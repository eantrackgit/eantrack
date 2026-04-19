import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/connectivity/presentation/no_connection_modal.dart';
import '../../../../core/error/app_exception.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../shared/shared.dart';
import '../../domain/auth_state.dart';
import '../providers/auth_provider.dart';

enum _EmailStatus { idle, checking, available, taken }

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen>
    with FormStateMixin<RegisterScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();

  _EmailStatus _emailStatus = _EmailStatus.idle;
  Timer? _emailDebounce;

  bool _termsAccepted = false;
  bool _termsError = false;
  AsyncAction<void> _action = const ActionIdle();
  AsyncAction<void> _googleAction = const ActionIdle();

  bool get _canSubmit {
    final email = _emailCtrl.text.trim();
    final emailOk = email.isNotEmpty &&
        AppValidators.email(email) == null &&
        _emailStatus != _EmailStatus.taken &&
        _emailStatus != _EmailStatus.checking;
    return emailOk && passwordValid && passwordsMatch && _termsAccepted;
  }

  @override
  void dispose() {
    _emailDebounce?.cancel();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  void _onEmailChanged(String value) {
    _emailDebounce?.cancel();

    if (value.trim().isEmpty || AppValidators.email(value) != null) {
      setState(() => _emailStatus = _EmailStatus.idle);
      return;
    }

    setState(() => _emailStatus = _EmailStatus.checking);
    _emailDebounce =
        Timer(const Duration(seconds: 2), () => _checkEmail(value));
  }

  Future<void> _checkEmail(String email) async {
    final available =
        await ref.read(authRepositoryProvider).checkEmailAvailable(email);
    if (!mounted) return;
    setState(() {
      _emailStatus = available ? _EmailStatus.available : _EmailStatus.taken;
    });
  }

  String? _emailFieldValidator(String? value) {
    final error = emailValidator(value);
    if (error != null || !submitted) return error;
    if (_emailStatus == _EmailStatus.taken) {
      return 'Este e-mail já está em uso.';
    }
    return null;
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
        title: 'Falha no cadastro com Google',
        message: e is AppException
            ? e.message
            : 'Falha ao entrar com Google. Tente novamente.',
        isGoogleFlow: true,
      );
    }
  }

  Future<void> _submit() async {
    setState(() {
      _termsError = !_termsAccepted;
      _action = const ActionIdle();
    });

    if (!validateAndSubmit()) return;
    if (_termsError) return;
    if (_emailStatus == _EmailStatus.taken) return;
    if (_emailStatus == _EmailStatus.checking) return;
    final isOnline =
        await ensureOnlineOrShowNoConnectionModal(context: context, ref: ref);
    if (!isOnline || !mounted) return;

    setState(() => _action = const ActionLoading());

    try {
      await ref.read(authNotifierProvider.notifier).signUp(
            email: _emailCtrl.text,
            password: _passwordCtrl.text,
          );
    } catch (e) {
      await _showActionErrorDialog(
        title: 'Falha ao criar conta',
        message: e is AppException
            ? e.message
            : 'Erro ao criar conta. Tente novamente.',
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
        case AuthEmailUnconfirmed():
          setState(() {
            _action = const ActionSuccess(null);
            _googleAction = const ActionSuccess(null);
          });
          context.go(AppRoutes.emailVerification);
        case AuthAuthenticated():
          setState(() {
            _action = const ActionSuccess(null);
            _googleAction = const ActionSuccess(null);
          });
          context.go(AppRoutes.flow);
        case AuthError(:final message):
          await _showActionErrorDialog(
            title: _googleAction.isLoading
                ? 'Falha no cadastro com Google'
                : 'Falha ao criar conta',
            message: message,
            isGoogleFlow: _googleAction.isLoading,
          );
        default:
          break;
      }
    });

    final isBusy = _action.isLoading || _googleAction.isLoading;

    final et = EanTrackTheme.of(context);

    return AuthScaffold(
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 190,
                  height: 68,
                  child: SvgPicture.asset(
                    'assets/images/eantrack.svg',
                    fit: BoxFit.contain,
                    alignment: Alignment.center,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Criar conta',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.headlineSmall.copyWith(
                    color: et.primaryText,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Todos os campos sao obrigatorios',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: et.secondaryText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              label: 'E-mail',
              hint: 'Digite seu e-mail',
              controller: _emailCtrl,
              focusNode: _emailFocus,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              validator: _emailFieldValidator,
              onChanged: _onEmailChanged,
              onFieldSubmitted: (_) =>
                  FocusScope.of(context).requestFocus(_passwordFocus),
            ),
            _EmailStatusHint(_emailStatus),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'Senha',
              hint: 'Digite sua senha',
              controller: _passwordCtrl,
              focusNode: _passwordFocus,
              isPassword: true,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
              validator: passwordValidator,
              onChanged: (value) => onPasswordChanged(value, _confirmCtrl),
              onFieldSubmitted: (_) =>
                  FocusScope.of(context).requestFocus(_confirmFocus),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'A senha deve ter:',
              style: AppTextStyles.bodySmall.copyWith(
                color: et.secondaryText,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Column(
              children: [
                PasswordRuleRow(
                  satisfied: hasUppercase,
                  label: 'Uma letra maiuscula',
                  isTyping: isTypingPassword,
                ),
                PasswordRuleRow(
                  satisfied: hasLowercase,
                  label: 'Uma letra minuscula',
                  isTyping: isTypingPassword,
                ),
                PasswordRuleRow(
                  satisfied: hasDigit,
                  label: 'Um numero',
                  isTyping: isTypingPassword,
                ),
                PasswordRuleRow(
                  satisfied: hasMinLength,
                  label: 'Minimo de 8 caracteres',
                  isTyping: isTypingPassword,
                ),
                PasswordRuleRow(
                  satisfied: hasSymbol,
                  label: 'Um simbolo (ex: @, #, \$, %, &, *)',
                  isTyping: isTypingPassword,
                ),
                PasswordRuleRow(
                  satisfied: passwordsMatch,
                  label: 'As senhas coincidem',
                  isTyping: isConfirmTyping,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'Confirmar senha',
              hint: 'Repita a senha',
              controller: _confirmCtrl,
              focusNode: _confirmFocus,
              isPassword: true,
              textInputAction: TextInputAction.done,
              validator: (value) => confirmValidator(value, _passwordCtrl),
              onChanged: (value) => onConfirmChanged(value, _passwordCtrl),
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: AppSpacing.lg),
            _TermsRow(
              accepted: _termsAccepted,
              hasError: _termsError,
              onChanged: (v) => setState(() {
                _termsAccepted = v ?? false;
                if (_termsAccepted) _termsError = false;
              }),
              onTermsTap: () => context.push(AppRoutes.termsOfUse),
              onPrivacyTap: () => context.push(AppRoutes.privacyPolicy),
            ),
            const SizedBox(height: AppSpacing.lg),
            const SizedBox(height: AppSpacing.sm),
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
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Voltar',
                    variant: AppButtonVariant.outlined,
                    leadingIcon: const Icon(Icons.arrow_back_ios, size: 14),
                    onPressed: isBusy ? null : () => context.go(AppRoutes.login),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    label: 'Criar conta',
                    trailingIcon: const Icon(Icons.arrow_forward_ios, size: 14),
                    onPressed: (isBusy || !_canSubmit) ? null : _submit,
                    isLoading: _action.isLoading,
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

class _EmailStatusHint extends StatelessWidget {
  const _EmailStatusHint(this.status);

  final _EmailStatus status;

  @override
  Widget build(BuildContext context) {
    final et = EanTrackTheme.of(context);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: switch (status) {
        _EmailStatus.idle => const SizedBox.shrink(),
        _EmailStatus.checking =>
          _hint(Icons.hourglass_empty, 'Verificando...', et.secondaryText),
        _EmailStatus.available =>
          _hint(Icons.check_circle_outline, 'Disponível', AppColors.success),
        _EmailStatus.taken => _hint(
            Icons.cancel_outlined,
            'Este e-mail já está em uso',
            AppColors.error,
          ),
      },
    );
  }

  Widget _hint(IconData icon, String text, Color color) {
    return Padding(
      key: ValueKey(status),
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(text, style: AppTextStyles.bodySmall.copyWith(color: color)),
        ],
      ),
    );
  }
}

class _TermsRow extends StatelessWidget {
  const _TermsRow({
    required this.accepted,
    required this.hasError,
    required this.onChanged,
    required this.onTermsTap,
    required this.onPrivacyTap,
  });

  final bool accepted;
  final bool hasError;
  final ValueChanged<bool?> onChanged;
  final VoidCallback onTermsTap;
  final VoidCallback onPrivacyTap;

  @override
  Widget build(BuildContext context) {
    final et = EanTrackTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Checkbox(
              value: accepted,
              onChanged: onChanged,
              activeColor: et.ctaBackground,
              checkColor: et.ctaForeground,
              side: BorderSide(
                color: hasError ? AppColors.error : et.inputBorder,
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(!accepted),
                child: RichText(
                  text: TextSpan(
                    style: AppTextStyles.bodySmall.copyWith(
                      color: et.primaryText,
                    ),
                    children: [
                      const TextSpan(text: 'Ao continuar, você concorda com os '),
                      WidgetSpan(
                        child: GestureDetector(
                          onTap: onTermsTap,
                          child: Text(
                            'Termos de Uso',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: et.accentLink,
                              decoration: TextDecoration.underline,
                              decorationColor: et.accentLink,
                            ),
                          ),
                        ),
                      ),
                      const TextSpan(text: '. Leia nossa '),
                      WidgetSpan(
                        child: GestureDetector(
                          onTap: onPrivacyTap,
                          child: Text(
                            'Politica de Privacidade.',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: et.accentLink,
                              decoration: TextDecoration.underline,
                              decorationColor: et.accentLink,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Text(
              'Para continuar, e necessario aceitar os Termos de Uso e a Politica de Privacidade.',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
            ),
          ),
      ],
    );
  }
}
