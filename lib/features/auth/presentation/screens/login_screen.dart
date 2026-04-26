import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/connectivity/presentation/no_connection_modal.dart';
import '../../../../core/connectivity/presentation/connection_status_icon.dart';
import '../../../../core/error/app_exception.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../shared/shared.dart';
import '../../domain/auth_state.dart';
import '../providers/auth_provider.dart';

enum LoginScreenNotice {
  recoveryEmailSent,
}

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({
    super.key,
    this.notice,
    this.consumeRecoveryQueryParam = false,
  });

  final LoginScreenNotice? notice;
  final bool consumeRecoveryQueryParam;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with FormStateMixin<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocus = FocusNode();
  ProviderSubscription<AuthState>? _authStateSubscription;
  AsyncAction<void> _action = const ActionIdle();
  AsyncAction<void> _googleAction = const ActionIdle();

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_onEmailChanged);
    _authStateSubscription = ref.listenManual<AuthState>(
      authNotifierProvider,
      (_, next) => _handleAuthStateChange(next),
    );

    if (widget.consumeRecoveryQueryParam) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        GoRouter.of(context).replace(
          AppRoutes.login,
          extra: widget.notice,
        );
      });
    }
  }

  @override
  void didUpdateWidget(covariant LoginScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.notice != widget.notice) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _authStateSubscription?.close();
    _emailController.removeListener(_onEmailChanged);
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _onEmailChanged() {
    if (widget.notice == LoginScreenNotice.recoveryEmailSent) {
      setState(() {});
    }
  }

  String? _normalizeEmail(String? email) {
    final normalized = email?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) return null;
    return normalized;
  }

  void _navigateAfterFrame(String route) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.go(route);
    });
  }

  Future<void> _handleAuthStateChange(AuthState next) async {
    if (!mounted) return;

    switch (next) {
      case AuthAuthenticated():
        setState(() {
          _action = const ActionSuccess(null);
          _googleAction = const ActionSuccess(null);
        });
        _navigateAfterFrame(AppRoutes.flow);
        return;
      case AuthEmailUnconfirmed():
        setState(() {
          _action = const ActionSuccess(null);
          _googleAction = const ActionSuccess(null);
        });
        _navigateAfterFrame(AppRoutes.emailVerification);
        return;
      case AuthError(:final message):
        await _showActionErrorDialog(
          title: _googleAction.isLoading
              ? 'Falha no login com Google'
              : 'Falha no login',
          message: message,
          isGoogleFlow: _googleAction.isLoading,
        );
        return;
      default:
        return;
    }
  }

  Future<void> _signInWithGoogle() async {
    final isOnline =
        await ensureOnlineOrShowNoConnectionModal(context: context, ref: ref);
    if (!isOnline || !mounted) return;

    setState(() => _googleAction = const ActionLoading());
    try {
      await ref.read(authNotifierProvider.notifier).signInWithGoogle();
    } catch (e) {
      await _showActionErrorDialog(
        title: 'Falha no login com Google',
        message: e is AppException
            ? e.message
            : 'Falha ao entrar com Google. Tente novamente.',
        isGoogleFlow: true,
      );
    }
  }

  Future<void> _submit() async {
    if (!validateAndSubmit()) return;
    final isOnline =
        await ensureOnlineOrShowNoConnectionModal(context: context, ref: ref);
    if (!isOnline || !mounted) return;

    setState(() => _action = const ActionLoading());
    try {
      await ref.read(authNotifierProvider.notifier).signIn(
            email: _emailController.text,
            password: _passwordController.text,
          );
    } catch (e) {
      await _showActionErrorDialog(
        title: 'Falha no login',
        message: e is AppException
            ? e.message
            : 'Erro ao realizar login. Tente novamente.',
      );
    }
  }

  Future<void> _showActionErrorDialog({
    required String title,
    required String message,
    bool isGoogleFlow = false,
  }) async {
    if (!mounted) return;
    setState(() {
      if (isGoogleFlow) {
        _googleAction = const ActionIdle();
      } else {
        _action = const ActionIdle();
      }
    });
    await AppFeedback.showError(context, title: title, message: message);
  }

  @override
  Widget build(BuildContext context) {
    final et = EanTrackTheme.of(context);

    final isBusy = _action.isLoading || _googleAction.isLoading;
    final recoveryEmail = _normalizeEmail(
      ref.watch(passwordRecoveryCooldownProvider).email,
    );
    final currentEmail = _normalizeEmail(_emailController.text);
    final showRecoveryEmailSentMessage =
        widget.notice == LoginScreenNotice.recoveryEmailSent &&
        recoveryEmail != null &&
        recoveryEmail == currentEmail;

    return AuthScaffold(
      action: const _TopBarActions(),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: SvgPicture.asset(
                'assets/images/eantrack.svg',
                width: 180,
                height: 60,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Center(
              child: Text(
                'Smart Tracking',
                style: AppTextStyles.bodySmall.copyWith(
                  color: et.secondaryText,
                ),
              ),
            ),
            if (showRecoveryEmailSentMessage) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: et.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: et.surfaceBorder),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.mark_email_read_outlined,
                        color: AppColors.success,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Enviamos o link de recuperação. Verifique sua caixa de entrada e spam para continuar.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: et.secondaryText,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              label: 'E-mail',
              hint: 'usuario@email.com',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              validator: emailValidator,
              onFieldSubmitted: (_) =>
                  FocusScope.of(context).requestFocus(_passwordFocus),
            ),
            const SizedBox(height: 12),
            AppTextField(
              label: 'Senha',
              hint: 'Digite sua senha',
              controller: _passwordController,
              focusNode: _passwordFocus,
              isPassword: true,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              validator: (value) {
                if (!submitted) return null;
                if (value == null || value.isEmpty) {
                  return 'Informe a senha.';
                }
                if (value.length < 8) {
                  return 'Minimo 8 caracteres.';
                }
                return null;
              },
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: 'Entrar',
              onPressed: isBusy ? null : _submit,
              isLoading: _action.isLoading,
            ),
            const SizedBox(height: AppSpacing.md),
            _DividerOu(),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: 'Entrar com Google',
              variant: AppButtonVariant.social,
              isLoading: _googleAction.isLoading,
              onPressed: isBusy ? null : _signInWithGoogle,
              leadingIcon: SvgPicture.asset(
                'assets/images/google_logo.svg',
                width: 20,
                height: 20,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: isBusy
                    ? null
                    : () => context.push(AppRoutes.recoverPassword),
                child: RichText(
                  text: TextSpan(
                    style: AppTextStyles.labelMedium,
                    children: [
                      TextSpan(
                        text: 'Esqueceu sua senha? ',
                        style: TextStyle(color: et.secondaryText),
                      ),
                      TextSpan(
                        text: 'Clique aqui',
                        style: TextStyle(
                          color: et.accentLink,
                          decoration: TextDecoration.underline,
                          decorationColor: et.accentLink,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: 'Criar conta',
              variant: AppButtonVariant.outlined,
              onPressed: isBusy ? null : () => context.push(AppRoutes.register),
            ),
            const SizedBox(height: AppSpacing.xs),
            Center(
              child: TextButton(
                onPressed: () => context.push(AppRoutes.validity),
                style: TextButton.styleFrom(
                  foregroundColor: et.secondaryText,
                  textStyle: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                child: const Text('Testar Validade'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Barra superior direita: ícone de conectividade + toggle de tema
// ---------------------------------------------------------------------------

class _TopBarActions extends StatelessWidget {
  const _TopBarActions();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: const [
        ConnectionStatusIcon(),
        SizedBox(width: 8),
        _ThemeToggleButton(),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Toggle de tema — posicionado pelo AuthScaffold no canto superior direito
// ---------------------------------------------------------------------------

class _ThemeToggleButton extends ConsumerWidget {
  const _ThemeToggleButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final isDark = mode == ThemeMode.dark;
    final et = EanTrackTheme.of(context);

    return Tooltip(
      message: isDark ? 'Modo claro' : 'Modo escuro',
      child: Material(
        color: et.surface.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            ref.read(themeModeProvider.notifier).state =
                isDark ? ThemeMode.light : ThemeMode.dark;
          },
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                key: ValueKey(isDark),
                size: 20,
                color: et.secondaryText,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Divisor "ou"
// ---------------------------------------------------------------------------

class _DividerOu extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final et = EanTrackTheme.of(context);
    return Row(
      children: [
        Expanded(child: Divider(color: et.divider)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Text(
            'ou',
            style: AppTextStyles.bodySmall.copyWith(
              color: et.secondaryText,
            ),
          ),
        ),
        Expanded(child: Divider(color: et.divider)),
      ],
    );
  }
}
