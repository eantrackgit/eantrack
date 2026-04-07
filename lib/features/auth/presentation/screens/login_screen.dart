import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

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
  AsyncAction<void> _action = const ActionIdle();
  AsyncAction<void> _googleAction = const ActionIdle();
  late bool _showRecoveryEmailSentMessage;

  @override
  void initState() {
    super.initState();
    _showRecoveryEmailSentMessage =
        widget.notice == LoginScreenNotice.recoveryEmailSent;

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
    if (!_showRecoveryEmailSentMessage &&
        widget.notice == LoginScreenNotice.recoveryEmailSent) {
      setState(() {
        _showRecoveryEmailSentMessage = true;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
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
    ref.listen<AuthState>(authNotifierProvider, (_, next) async {
      if (!mounted) return;
      switch (next) {
        case AuthAuthenticated():
          setState(() {
            _action = const ActionSuccess(null);
            _googleAction = const ActionSuccess(null);
          });
          context.go(AppRoutes.flow);
        case AuthEmailUnconfirmed():
          setState(() {
            _action = const ActionSuccess(null);
            _googleAction = const ActionSuccess(null);
          });
          context.go(AppRoutes.emailVerification);
        case AuthError(:final message):
          await _showActionErrorDialog(
            title: _googleAction.isLoading
                ? 'Falha no login com Google'
                : 'Falha no login',
            message: message,
            isGoogleFlow: _googleAction.isLoading,
          );
        default:
          break;
      }
    });

    final isBusy = _action.isLoading || _googleAction.isLoading;

    return AuthScaffold(
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                onPressed: () {},
                icon: const Icon(
                  Icons.headset_mic_outlined,
                  size: 20,
                  color: AppColors.secondaryText,
                ),
              ),
            ),
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
                  color: AppColors.secondaryText,
                ),
              ),
            ),
            if (_showRecoveryEmailSentMessage) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.secondaryBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.alternate),
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
                        'Enviamos o link de recuperacao. Verifique sua caixa de entrada e spam para continuar.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.secondaryText,
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
              leadingIcon: const FaIcon(
                FontAwesomeIcons.squareGooglePlus,
                size: 20,
                color: AppColors.secondaryBackground,
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
                    children: const [
                      TextSpan(
                        text: 'Esqueceu sua senha? ',
                        style: TextStyle(
                          color: AppColors.secondaryText,
                        ),
                      ),
                      TextSpan(
                        text: 'Clique aqui',
                        style: TextStyle(
                          color: AppColors.actionBlue,
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.actionBlue,
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
            const SizedBox(height: AppSpacing.md),
            Column(
              children: [
                const Icon(
                  Icons.fingerprint,
                  size: 32,
                  color: AppColors.secondaryText,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Entre com biometria',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DividerOu extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.accent1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Text(
            'ou',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.secondaryText,
            ),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.accent1)),
      ],
    );
  }
}
