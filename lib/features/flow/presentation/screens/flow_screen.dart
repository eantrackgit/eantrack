import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import '../../../../core/audio/beep_player.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../features/auth/domain/auth_state.dart';
import '../../../../features/auth/domain/auth_flow_state.dart';
import '../../../../features/auth/domain/user_flow_state.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../features/auth/presentation/widgets/keep_connected_prompt_dialog.dart';
import '../../../../shared/shared.dart';
import '../widgets/auth_fallback_screen.dart';

/// Tela transitória central de decisão do fluxo de auth.
/// Lê [AuthFlowState] e encaminha automaticamente o usuário.
class FlowScreen extends ConsumerStatefulWidget {
  const FlowScreen({super.key});

  @override
  ConsumerState<FlowScreen> createState() => _FlowScreenState();
}

class _FlowScreenState extends ConsumerState<FlowScreen> {
  ProviderSubscription<AuthFlowState>? _authFlowSubscription;
  // Segunda fonte de gatilho da decisão: o estado bruto do AuthNotifier.
  // O authFlowStateProvider deriva um enum e só notifica quando esse enum
  // MUDA de valor. Na transição AuthLoading -> AuthAuthenticated de um usuário
  // que ainda precisa de onboarding, o enum permanece `onboardingRequired`
  // (sem mudança), então um listener só de authFlowStateProvider não reavalia
  // a decisão -- e a tela ficava presa no loading até o _safetyTimer (10s).
  // Ouvir authNotifierProvider cobre exatamente essa transição que o enum
  // esconde.
  ProviderSubscription<AuthState>? _authStateSubscription;
  Timer? _safetyTimer;

  // /flow é a única rota que o GoRouter nunca redireciona (ver app_router.dart
  // -- `if (path == AppRoutes.flow) return null`). Ela é o gateway de auth de
  // toda rota protegida: se a auth não resolver dentro deste prazo (loading
  // travado, callback OAuth sem resposta, erro silencioso), o usuário não
  // pode ficar preso numa tela só com animação. O desfecho do timeout NÃO é
  // sempre o fallback -- ver _handleAuthTimeout: sem sessão é login direto,
  // fallback é reservado para quando existe sessão mas o contexto não
  // confirmou a tempo.
  static const Duration _authTimeout = Duration(seconds: 10);

  // Tempo mínimo que a animação de carregamento fica visível antes de navegar.
  // Dimensionado para a sequência completa do _EanAccessLoader (scan do EAN ->
  // "acesso liberado" -> check) + um respiro maior no estado liberado antes de
  // sair. Mesmo quando a auth resolve quase instantaneamente, seguramos a tela
  // por este período -> a transição "tudo certo" sempre acontece, e ainda abre
  // uma janela limpa para o teardown da tela anterior concluir antes da próxima
  // rota montar.
  static const Duration _minLoadingDisplay = Duration(milliseconds: 3600);
  late final DateTime _loadingShownAt;

  bool _isNavigating = false;
  bool _isResolvingOnboardingRoute = false;
  bool _isPromptingKeepConnected = false;
  bool _showFallback = false;
  bool _isRetrying = false;
  final Set<String> _promptCheckedUserIds = <String>{};

  // Diagnóstico opcional da linha do tempo de /flow (timestamps relativos ao
  // mount da tela). Desligado por padrão para não poluir os logs; ligue
  // localmente (_debugTimeline = true) para inspecionar onde o tempo é gasto.
  static const bool _debugTimeline = false;
  final Stopwatch _watch = Stopwatch();

  void _t(String message) {
    if (!_debugTimeline) return;
    final ms = _watch.elapsedMilliseconds.toString().padLeft(4, '0');
    debugPrint('[FlowDebug +${ms}ms] $message');
  }

  @override
  void initState() {
    super.initState();
    _loadingShownAt = DateTime.now();
    _watch.start();
    _t('FlowScreen init authState=${ref.read(authNotifierProvider).runtimeType}');
    _authFlowSubscription = ref.listenManual<AuthFlowState>(
      authFlowStateProvider,
      (_, next) {
        _t('authFlowState -> $next');
        _scheduleDecision(next);
      },
    );
    // Reavalia a decisão também quando o AuthState bruto muda (ex.:
    // AuthLoading -> AuthAuthenticated), inclusive quando o enum derivado por
    // authFlowStateProvider permanece o mesmo (onboardingRequired). Sem isto,
    // usuários que precisam de onboarding só destravavam pelo _safetyTimer.
    _authStateSubscription = ref.listenManual<AuthState>(
      authNotifierProvider,
      (_, next) {
        _t('authState -> ${next.runtimeType}');
        _scheduleDecision(ref.read(authFlowStateProvider));
      },
    );
    _startSafetyTimer();
    _scheduleDecision(ref.read(authFlowStateProvider));
  }

  @override
  void dispose() {
    _safetyTimer?.cancel();
    _authFlowSubscription?.close();
    _authStateSubscription?.close();
    super.dispose();
  }

  void _startSafetyTimer() {
    _safetyTimer?.cancel();
    _safetyTimer = Timer(_authTimeout, _handleAuthTimeout);
  }

  // Estourou _authTimeout sem o fluxo se resolver (nem login, nem hub/
  // onboarding, nem fallback). A causa raiz do fallback indevido em produção
  // era tratar esse timeout sempre como erro: usuário sem sessão alguma
  // também caía aqui e via a tela de erro em vez de ir pro login.
  //
  // Regra: login é o caminho comum para "sem sessão"; fallback é exceção,
  // reservada para quando existe sessão (currentUser != null) mas o
  // contexto (getUserFlowState) não confirmou a tempo -- mesmo após uma
  // revalidação (cobre o caso de o listener de auth ter perdido a emissão
  // original do stream).
  Future<void> _handleAuthTimeout() async {
    if (!mounted ||
        _isNavigating ||
        _showFallback ||
        _isResolvingOnboardingRoute ||
        _isPromptingKeepConnected) {
      return;
    }

    _t('safety timeout (10s) atingido');
    final user = Supabase.instance.client.auth.currentUser;
    var authState = ref.read(authNotifierProvider);
    _logAuthDecision('timeout', user: user, authState: authState);

    if (user == null || authState is AuthUnauthenticated) {
      _go(AppRoutes.login);
      return;
    }

    if (authState is AuthError) {
      _showSafeFallback();
      return;
    }

    // Existe usuário mas o AuthState ainda não chegou a Authenticated/Error
    // -- tenta revalidar uma vez antes de desistir.
    await ref.read(authNotifierProvider.notifier).retryAuthCheck();
    if (!mounted || _isNavigating || _showFallback) return;

    authState = ref.read(authNotifierProvider);
    _logAuthDecision('timeout-revalidated', user: user, authState: authState);

    if (authState is AuthUnauthenticated) {
      _go(AppRoutes.login);
      return;
    }

    if (authState is AuthAuthenticated) {
      // Reabre a janela de segurança: se _decide ainda assim ficar "aguardando"
      // (ex.: flowState ambíguo), o usuário não pode perder a rede de segurança.
      _startSafetyTimer();
      _scheduleDecision(ref.read(authFlowStateProvider));
      return;
    }

    _showSafeFallback();
  }

  // Mostra o fallback seguro (título + mensagem + "Tentar novamente"/"Voltar
  // para login"). Chamado tanto por _handleAuthTimeout quanto por AuthError
  // confirmado em _resolveOnboardingRouteFromState.
  void _showSafeFallback() {
    if (!mounted || _showFallback) return;
    debugPrint('[FlowScreen] Exibindo fallback seguro de autenticacao.');
    setState(() => _showFallback = true);
  }

  // Log só de diagnóstico (sem token/refresh token): motivo da decisão,
  // se havia usuário no Supabase e o tipo de AuthState no momento.
  void _logAuthDecision(String reason, {required User? user, required AuthState authState}) {
    debugPrint(
      '[FlowScreen] decisao=$reason currentUser=${user != null ? "presente" : "ausente"} '
      'authState=${authState.runtimeType}',
    );
  }

  void _scheduleDecision(AuthFlowState flowState) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _decide(flowState);
    });
  }

  void _go(String route) {
    if (!mounted || _isNavigating) return;
    _t('go $route');
    _isNavigating = true;
    _showFallback = false;

    // Garante o tempo mínimo de exibição da animação de carregamento. Como
    // _isNavigating já está travado, nenhuma decisão concorrente dispara
    // navegação durante a espera, e o _safetyTimer (10s) também ignora este
    // intervalo (ele checa _isNavigating antes de agir).
    final remaining =
        _minLoadingDisplay - DateTime.now().difference(_loadingShownAt);
    if (remaining > Duration.zero) {
      Timer(remaining, () {
        if (!mounted) return;
        _performGo(route);
      });
    } else {
      _performGo(route);
    }
  }

  void _performGo(String route) {
    if (!mounted) return;
    context.go(route);
    // Se o router redirecionar de volta para /flow, a instância permanece
    // montada. Nesse caso, resetar e re-tentar com o estado atual.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _isNavigating = false;
      _isResolvingOnboardingRoute = false;
      _startSafetyTimer();
      _scheduleDecision(ref.read(authFlowStateProvider));
    });
  }

  // "Tentar novamente": reexecuta a verificação de auth (AuthNotifier.
  // retryAuthCheck) e reavalia o fluxo. Reabre a janela de timeout para a
  // nova tentativa.
  Future<void> _retryAuthCheck() async {
    if (_isRetrying) return;
    setState(() => _isRetrying = true);
    _logAuthDecision(
      'retry-tap',
      user: Supabase.instance.client.auth.currentUser,
      authState: ref.read(authNotifierProvider),
    );
    try {
      // AuthNotifier.retryAuthCheck() já decide internamente: sem
      // currentUser vira AuthUnauthenticated (login, via _decide abaixo);
      // com currentUser, refaz a verificação de contexto.
      await ref.read(authNotifierProvider.notifier).retryAuthCheck();
    } finally {
      if (!mounted) return;
      setState(() {
        _isRetrying = false;
        _showFallback = false;
      });
      _startSafetyTimer();
      _scheduleDecision(ref.read(authFlowStateProvider));
    }
  }

  // "Voltar para login": encerra apenas a sessão local (ver
  // AuthNotifier.abandonToLogin). O cache local do Lembrar-me não é tocado
  // aqui de propósito -- o keep_connected real nunca foi confirmado neste
  // fluxo, então limpar o cache por suposição poderia apagar uma conta salva
  // válida.
  Future<void> _backToLogin() async {
    _logAuthDecision(
      'back-to-login-tap',
      user: Supabase.instance.client.auth.currentUser,
      authState: ref.read(authNotifierProvider),
    );
    await ref.read(authNotifierProvider.notifier).abandonToLogin();
    if (!mounted) return;
    _go(AppRoutes.login);
  }

  void _decide(AuthFlowState flowState) {
    if (!mounted || _isNavigating) return;

    _t('decide flowState=$flowState '
        'authState=${ref.read(authNotifierProvider).runtimeType}');
    switch (flowState) {
      case AuthFlowState.unauthenticated:
        _go(AppRoutes.login);
        return;
      case AuthFlowState.recovery:
        _go(AppRoutes.updatePassword);
        return;
      case AuthFlowState.onboardingRequired:
        _resolveOnboardingRouteFromState();
        return;
      case AuthFlowState.authenticated:
        _goAfterKeepConnectedPrompt(AppRoutes.hub);
        return;
    }
  }

  Future<void> _goAfterKeepConnectedPrompt(String route) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      _go(AppRoutes.login);
      return;
    }

    final canContinue = await _ensureKeepConnectedPromptAnswered(user);
    if (!mounted || !canContinue || _isNavigating) return;
    _go(route);
  }

  Future<bool> _ensureKeepConnectedPromptAnswered(User user) async {
    if (_promptCheckedUserIds.contains(user.id)) return true;
    if (_isPromptingKeepConnected) return false;

    _isPromptingKeepConnected = true;
    try {
      final controller = ref.read(keepConnectedControllerProvider.notifier);

      // Single read confirming keep_connected for this login and syncing
      // the local saved-email cache (true -> cache email, false -> clear).
      await controller.syncAfterLogin(user.id, user.email);
      if (!mounted) return false;

      // Local-only check: shows the dialog at most once per userId/device.
      final shouldShowPrompt = await controller.shouldShowPrompt(user.id);
      if (!mounted) return false;

      if (shouldShowPrompt) {
        // "Agora nao" only records the preference for future app starts; it
        // must not interrupt the session that was just authenticated.
        final answered = await showKeepConnectedPromptDialog(
          context: context,
          userId: user.id,
          loginEmail: user.email,
        );
        if (!mounted || !answered) return false;
      }

      _promptCheckedUserIds.add(user.id);
      return true;
    } finally {
      _isPromptingKeepConnected = false;
    }
  }

  String _routeFromUserFlowState(UserFlowState? flowState) {
    if (flowState == null) return AppRoutes.onboarding;

    switch (flowState.normalizedUserMode) {
      case null:
        return AppRoutes.onboarding;
      case 'individual':
        return flowState.hasProfile
            ? AppRoutes.hub
            : AppRoutes.onboardingIndividualProfile;
      case 'agency':
        final agencyId = flowState.agencyId?.trim();
        if (agencyId == null || agencyId.isEmpty) {
          return AppRoutes.onboardingAgencyCnpj;
        }

        if (flowState.hasLegalRepresentative == true) {
          return AppRoutes.onboardingAgencyStatus;
        }

        return AppRoutes.onboardingAgencyRepresentative;
      default:
        return AppRoutes.onboarding;
    }
  }

  Future<void> _resolveOnboardingRouteFromState() async {
    if (_isResolvingOnboardingRoute || _isNavigating) return;

    final authState = ref.read(authNotifierProvider);

    // onExternalAuthChange já concluiu com falha definitiva (ex.:
    // getUserFlowState sem resposta). Não há nada a aguardar -- mostra o
    // fallback seguro imediatamente em vez de esperar _authTimeout.
    if (authState is AuthError) {
      _logAuthDecision(
        'auth-error',
        user: Supabase.instance.client.auth.currentUser,
        authState: authState,
      );
      _showSafeFallback();
      return;
    }

    // Sem sessão confirmada (ex.: sessão restaurada foi descartada por
    // keep_connected=false): login direto, nunca fallback.
    if (authState is AuthUnauthenticated) {
      _logAuthDecision(
        'unauthenticated',
        user: Supabase.instance.client.auth.currentUser,
        authState: authState,
      );
      _go(AppRoutes.login);
      return;
    }

    if (authState is! AuthAuthenticated) {
      // AuthNotifier ainda não resolveu o login (ex.: onExternalAuthChange
      // em andamento após callback OAuth do Google). Não chamar
      // _ensureKeepConnectedPromptAnswered/syncAfterLogin com base num
      // user_id ainda não confirmado — isso poderia limpar o cache local
      // de "Conta salva" de outro usuário antes do auth/onboarding estar
      // decidido. Apenas aguardar: quando o AuthNotifier chegar a
      // AuthAuthenticated (ou AuthError/Unauthenticated), o
      // _authStateSubscription dispara _scheduleDecision e _decide roda de
      // novo -- sem depender de o enum derivado mudar de valor (ele pode
      // permanecer onboardingRequired). O _safetyTimer segue como rede de
      // segurança final.
      _t('aguardando authState resolver (atual=${authState.runtimeType})');
      return;
    }

    _isResolvingOnboardingRoute = true;
    try {
      final canContinue =
          await _ensureKeepConnectedPromptAnswered(authState.user);
      if (!mounted || !canContinue || _isNavigating) return;
      final route = _routeFromUserFlowState(authState.flowState);
      _t('navigate onboarding route=$route');
      _go(route);
    } on Exception catch (e) {
      debugPrint('[FlowScreen] Erro ao resolver fluxo: $e');
      if (mounted && !_isNavigating) {
        _go(AppRoutes.onboarding);
      }
    } finally {
      if (mounted) {
        _isResolvingOnboardingRoute = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showFallback) {
      return AuthFallbackScreen(
        isRetrying: _isRetrying,
        onRetry: _retryAuthCheck,
        onBackToLogin: _backToLogin,
      );
    }

    final et = EanTrackTheme.of(context);
    return Scaffold(
      backgroundColor: et.scaffoldOuter,
      body: Center(
        child: _EanAccessLoader(
          barColor: et.secondaryText,
          scanColor: et.accentLink,
          successColor: AppColors.success,
          textColor: et.secondaryText,
        ),
      ),
    );
  }
}

// ===========================================================================
// _EanAccessLoader — animação central do /flow: "scan do EAN -> acesso
// liberado".
//
// CONCEITO
// O código de barras (EAN) é a animação principal da tela de carregamento, no
// lugar de um Lottie genérico: ele é "lido" por uma linha de scan e, ao final,
// a leitura é confirmada com um selo de check e o texto cruza de "Carregando"
// para "Tudo certo" -- a metáfora de "acesso liberado" da marca EANTrack.
//
// LINHA DO TEMPO (controller _seq, ~2.6s, roda uma vez)
//   [0.00 - 0.55]  SCAN     -> a linha varre o código da esquerda p/ a direita;
//                              cada barra "lida" acende e permanece acesa.
//   [~0.60]        FLASH    -> pulso curto de brilho: confirmação da leitura.
//   [0.62 - 1.00]  LIBERADO -> o código recua, o selo de check cresce (com halo
//                              que expande e some) e "Carregando" -> "Tudo
//                              certo". Ao terminar, o selo fica respirando
//                              (controller _breath) até o FlowScreen navegar.
//
// O tempo total casa com FlowScreen._minLoadingDisplay (~3.3s): a sequência
// termina e descansa no estado liberado por um instante antes da navegação,
// reforçando a leitura de "entrou".
// ===========================================================================
class _EanAccessLoader extends StatefulWidget {
  const _EanAccessLoader({
    required this.barColor,
    required this.scanColor,
    required this.successColor,
    required this.textColor,
  });

  /// Cor das barras ainda não lidas (esmaecida).
  final Color barColor;

  /// Cor da linha de scan e das barras já lidas (destaque da marca).
  final Color scanColor;

  /// Cor do selo "liberado" e do texto "Tudo certo".
  final Color successColor;

  /// Cor do texto "Carregando".
  final Color textColor;

  @override
  State<_EanAccessLoader> createState() => _EanAccessLoaderState();
}

class _EanAccessLoaderState extends State<_EanAccessLoader>
    with TickerProviderStateMixin {
  // Linha do tempo principal scan -> liberado (roda uma vez e descansa em 1.0).
  late final AnimationController _seq = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..forward();

  // Respiro sutil do brilho verde "liberado", para o estado final não parecer
  // congelado enquanto o FlowScreen ainda aguarda a navegação.
  late final AnimationController _breath = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  // Garante que o beep toque uma única vez (quando a linha chega ao fim do EAN).
  bool _beeped = false;

  @override
  void initState() {
    super.initState();
    _seq.addListener(_maybeBeep);
  }

  /// "Beepou, liberou": dispara o beep no exato momento em que a leitura
  /// alcança a borda direita do código (fim da fase de scan).
  void _maybeBeep() {
    if (!_beeped && _seq.value >= 0.55) {
      _beeped = true;
      playBeep();
    }
  }

  @override
  void dispose() {
    _seq.dispose();
    _breath.dispose();
    super.dispose();
  }

  /// Normaliza o trecho [a, b] da timeline global para 0..1 (fora dele, satura
  /// em 0 ou 1). Base de todas as fases.
  double _seg(double t, double a, double b) =>
      ((t - a) / (b - a)).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: Listenable.merge([_seq, _breath]),
        builder: (context, _) {
          final t = _seq.value;

          // --- Frações por fase ------------------------------------------
          // Leitor horizontal descendo (0 = topo -> 1 = base) sobre o código.
          final scanY = Curves.easeInOut.transform(_seg(t, 0.0, 0.55));
          // Linha de scan visível só durante a leitura.
          final scanning = t < 0.56;
          // Flash branco curto no instante do beep (a linha chega à base).
          final flash = (1 - (t - 0.56).abs() / 0.05).clamp(0.0, 1.0);
          // "Liberou": após o beep, o EAN inteiro migra para verde (e assim
          // permanece até o fim -- o EAN animado não desaparece).
          final grant = Curves.easeOutCubic.transform(_seg(t, 0.56, 0.8));
          // Check verde: entrada moderna em sintonia com o beep -- pop com leve
          // overshoot + um anel "ping" que irradia uma vez (eco visual do
          // beep). Fica ACIMA do EAN, que permanece verde.
          final checkPop = Curves.easeOutBack.transform(_seg(t, 0.82, 1.0));
          final checkOpacity = _seg(t, 0.82, 0.92);
          final ringProg = Curves.easeOut.transform(_seg(t, 0.82, 0.98));
          // Cruzamento de rótulos.
          final carregandoOpacity = 1 - _seg(t, 0.58, 0.70);
          final tudoCertoOpacity = _seg(t, 0.64, 0.82);
          // Respiros sutis após a sequência terminar: glow verde e o check.
          final glowBreath = _seq.isCompleted ? (0.8 + 0.2 * _breath.value) : 1.0;
          final checkBreath =
              _seq.isCompleted ? (0.98 + 0.02 * _breath.value) : 1.0;

          final barcode = DecoratedBox(
            // Halo verde ao redor do código quando libera.
            decoration: BoxDecoration(
              boxShadow: grant > 0
                  ? [
                      BoxShadow(
                        color: widget.successColor.withValues(
                          alpha: 0.30 * grant * glowBreath,
                        ),
                        blurRadius: 26 * grant,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: CustomPaint(
              size: const Size(208, 60),
              painter: _EanScanPainter(
                scanY: scanning ? scanY : null,
                flash: flash,
                grant: grant,
                barColor: widget.barColor,
                scanColor: widget.scanColor,
                successColor: widget.successColor,
              ),
            ),
          );

          // "Números" do código (humano-legível): a marca escrita como um
          // EAN-13 (grupos 1|5|7), começando pelo prefixo 789 (GS1 Brasil) e
          // completada com 0. Fica OCULTA durante a leitura; quando a linha
          // termina o scan, os caracteres se revelam da esquerda para a direita
          // (cada posição sai de '0' para o dígito final) -- como um PDV
          // decodificando o código recém-lido. Acompanha a cor: esmaecido na
          // leitura -> verde no "liberou".
          final captionOpacity = _seg(t, 0.56, 0.66);
          final captionReveal = _seg(t, 0.58, 0.84);
          // Os dígitos (789/00) somem um pouco ANTES do fim; EANTRACK fica.
          final numbersFade = _seg(t, 0.9, 0.99);
          // No mesmo instante em que EANTRACK fica isolado, a marca dá um pop
          // de escala (com leve overshoot) -> destaque moderno. Transform.scale
          // é paint-time -> não causa reflow; EANTRACK cresce centralizado.
          final eanScale = 1 + 0.16 * Curves.easeOutBack.transform(numbersFade);
          final caption = Opacity(
            opacity: captionOpacity,
            child: Transform.scale(
              scale: eanScale,
              child: _EanCodeReveal(
                reveal: captionReveal,
                numbersFade: numbersFade,
                color: Color.lerp(
                  widget.barColor.withValues(alpha: 0.8),
                  widget.successColor,
                  grant,
                )!,
              ),
            ),
          );

          // Check verde grande (com anel "ping"). Área reservada desde o início
          // -> entra sem empurrar o layout. Clip.none deixa o anel irradiar
          // além da caixa.
          final check = SizedBox(
            width: 110,
            height: 104,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                if (ringProg > 0 && ringProg < 1)
                  Opacity(
                    opacity: (1 - ringProg) * 0.45,
                    child: Transform.scale(
                      scale: 0.55 + ringProg * 1.3,
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: widget.successColor,
                            width: 2.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                Opacity(
                  opacity: checkOpacity,
                  child: Transform.scale(
                    scale: checkPop * checkBreath,
                    child: Icon(
                      Icons.check_circle_rounded,
                      size: 96,
                      color: widget.successColor,
                      shadows: [
                        Shadow(
                          color: widget.successColor.withValues(alpha: 0.5),
                          blurRadius: 22,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );

          // "Tudo certo" / "Carregando" ocupam o mesmo lugar e se cruzam --
          // posicionados logo ABAIXO do check.
          final statusText = SizedBox(
            height: 24,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Opacity(
                  opacity: carregandoOpacity,
                  child: Text(
                    'Carregando',
                    style: AppTextStyles.titleSmall.copyWith(
                      color: widget.textColor,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                Opacity(
                  opacity: tudoCertoOpacity,
                  // Cor tema (azul) + brilho que percorre o texto -> destaca-se
                  // do verde do código/EAN e dá um movimento de cor sutil.
                  child: ShaderMask(
                    blendMode: BlendMode.srcIn,
                    shaderCallback: (bounds) {
                      final shift = _breath.value * 2 - 1; // -1..1 vai-e-volta
                      return LinearGradient(
                        begin: Alignment(shift - 0.7, 0),
                        end: Alignment(shift + 0.7, 0),
                        colors: [
                          widget.scanColor,
                          Color.lerp(widget.scanColor, Colors.white, 0.65)!,
                          widget.scanColor,
                        ],
                        stops: const [0.3, 0.5, 0.7],
                      ).createShader(bounds);
                    },
                    child: Text(
                      'Tudo certo',
                      style: AppTextStyles.titleSmall.copyWith(
                        color: Colors.white, // substituído pelo shader (srcIn)
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );

          // Ordem: check -> "Tudo certo" (logo abaixo) -> EAN -> número lido.
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              check,
              const SizedBox(height: AppSpacing.xs),
              statusText,
              const SizedBox(height: AppSpacing.lg),
              barcode,
              const SizedBox(height: 8),
              caption,
            ],
          );
        },
      ),
    );
  }
}

/// Linha humano-legível do EAN-13 que se revela como um PDV decodificando o
/// código: 13 caracteres em grupos 1|5|7 (prefixo 789 + EANTRACK completado com
/// 0). Cada posição mostra '0' até a frente de revelação ([reveal], 0..1) passar
/// por ela, quando troca para o caractere final. Slots de largura fixa evitam
/// jitter horizontal enquanto os glifos mudam.
class _EanCodeReveal extends StatelessWidget {
  const _EanCodeReveal({
    required this.reveal,
    required this.numbersFade,
    required this.color,
  });

  final double reveal;

  /// 0..1: some com os DÍGITOS (prefixo 789 + sufixo 00) perto do fim,
  /// mantendo as letras de EANTRACK até o final.
  final double numbersFade;
  final Color color;

  // Grupos do EAN-13 (1 | 5 | 7). Concatenados soletram 789 + EANTRACK + 00,
  // com o corte caindo entre "EAN" e "TRACK" -> a marca lê "EAN TRACK".
  static const List<String> _groups = ['7', '89EAN', 'TRACK00'];

  @override
  Widget build(BuildContext context) {
    final total = _groups.fold<int>(0, (a, g) => a + g.length);
    final revealedCount = (reveal * total).floor();
    final style = AppTextStyles.labelSmall.copyWith(
      color: color,
      fontWeight: FontWeight.w700,
      height: 1,
    );

    final slots = <Widget>[];
    var idx = 0;
    for (var g = 0; g < _groups.length; g++) {
      if (g > 0) slots.add(const SizedBox(width: 8)); // espaço entre grupos
      for (final ch in _groups[g].split('')) {
        final shown = idx < revealedCount ? ch : '0';
        // Dígito (789/00) -> some no fim; letra (EANTRACK) -> permanece.
        final code = ch.codeUnitAt(0);
        final isDigit = code >= 0x30 && code <= 0x39;
        final opacity = isDigit ? (1 - numbersFade).clamp(0.0, 1.0) : 1.0;
        slots.add(
          SizedBox(
            width: 13,
            child: Opacity(
              opacity: opacity,
              child: Text(shown, textAlign: TextAlign.center, style: style),
            ),
          ),
        );
        idx++;
      }
    }

    return Row(mainAxisSize: MainAxisSize.min, children: slots);
  }
}

/// Pinta o código de barras (padrão fixo estilo EAN) com um leitor que desce
/// na horizontal e a transição "liberou" (verde).
///
/// - [scanY] (0..1, ou null): posição vertical da linha de leitura, que desce
///   de cima (0) até a base (1); null quando a leitura terminou.
/// - [flash] (0..1): clareia o conjunto no instante do beep.
/// - [grant] (0..1): após o beep, interpola TODO o código para [successColor]
///   (verde) -- é o "liberou".
class _EanScanPainter extends CustomPainter {
  _EanScanPainter({
    required this.scanY,
    required this.flash,
    required this.grant,
    required this.barColor,
    required this.scanColor,
    required this.successColor,
  });

  final double? scanY;
  final double flash;
  final double grant;
  final Color barColor;
  final Color scanColor;
  final Color successColor;

  // Larguras em "unidades" alternando barra/espaço (índices pares = barra).
  // Guard bars finas nas pontas + miolo variado -> silhueta de EAN crível.
  static const List<double> _pattern = [
    1, 1, 1, 2, 1, 3, 1, 1, 2, 1, 1, 2, 3, 1, 1, 1, 2, 1, 1, 3, 1, 2, //
    1, 1, 2, 1, 1, 3, 1, 1, 2, 1, 1, 1,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final totalUnits = _pattern.fold<double>(0, (a, b) => a + b);
    final unit = size.width / totalUnits;

    final paint = Paint()..style = PaintingStyle.fill;
    final dimColor = barColor.withValues(alpha: 0.45);

    // Barras: esmaecidas durante a leitura; viram verde (successColor) após o
    // beep via [grant]; flash branco no instante da confirmação.
    var color = dimColor;
    if (grant > 0) color = Color.lerp(dimColor, successColor, grant)!;
    if (flash > 0) color = Color.lerp(color, Colors.white, flash * 0.6)!;
    paint.color = color;

    var x = 0.0;
    var isBar = true;
    for (final w in _pattern) {
      final barWidth = w * unit;
      if (isBar) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, 0, barWidth, size.height),
            const Radius.circular(1),
          ),
          paint,
        );
      }
      x += barWidth;
      isBar = !isBar;
    }

    // Leitor: linha HORIZONTAL que desce. Uma banda de brilho acompanha a
    // linha (as barras "acendem" enquanto ela passa) + traço nítido com halo.
    if (scanY != null) {
      final sy = scanY! * size.height;

      final band = Rect.fromLTWH(0, sy - 8, size.width, 16);
      canvas.drawRect(
        band,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              scanColor.withValues(alpha: 0.0),
              scanColor.withValues(alpha: 0.35),
              scanColor.withValues(alpha: 0.0),
            ],
          ).createShader(band),
      );

      final p1 = Offset(-4, sy);
      final p2 = Offset(size.width + 4, sy);
      canvas.drawLine(
        p1,
        p2,
        Paint()
          ..color = scanColor.withValues(alpha: 0.28)
          ..strokeWidth = 6
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawLine(
        p1,
        p2,
        Paint()
          ..color = scanColor
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_EanScanPainter old) =>
      old.scanY != scanY ||
      old.flash != flash ||
      old.grant != grant ||
      old.barColor != barColor ||
      old.scanColor != scanColor ||
      old.successColor != successColor;
}
