import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  bool _isNavigating = false;
  bool _isResolvingOnboardingRoute = false;
  bool _isPromptingKeepConnected = false;
  bool _showFallback = false;
  bool _isRetrying = false;
  final Set<String> _promptCheckedUserIds = <String>{};

  @override
  void initState() {
    super.initState();
    _authFlowSubscription = ref.listenManual<AuthFlowState>(
      authFlowStateProvider,
      (_, next) => _scheduleDecision(next),
    );
    _startSafetyTimer();
    _scheduleDecision(ref.read(authFlowStateProvider));
  }

  @override
  void dispose() {
    _safetyTimer?.cancel();
    _authFlowSubscription?.close();
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
    _isNavigating = true;
    _showFallback = false;
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
      // AuthAuthenticated (ou AuthError/Unauthenticated, cobertos pelo
      // _safetyTimer), authFlowStateProvider re-emite e _decide roda de novo.
      return;
    }

    _isResolvingOnboardingRoute = true;
    try {
      final canContinue =
          await _ensureKeepConnectedPromptAnswered(authState.user);
      if (!mounted || !canContinue || _isNavigating) return;
      _go(_routeFromUserFlowState(authState.flowState));
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
        child: Lottie.asset(
          'assets/animations/flow_loading.json',
          width: 180,
          repeat: true,
          animate: true,
        ),
      ),
    );
  }
}
