import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../shared/shared.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';
import '../widgets/resend_cooldown_button.dart';

class RecoverPasswordScreen extends ConsumerStatefulWidget {
  const RecoverPasswordScreen({super.key});

  @override
  ConsumerState<RecoverPasswordScreen> createState() =>
      _RecoverPasswordScreenState();
}

class _RecoverPasswordScreenState extends ConsumerState<RecoverPasswordScreen>
    with FormStateMixin<RecoverPasswordScreen> {
  final _emailCtrl = TextEditingController();
  AsyncAction<void> _action = const ActionIdle();
  Timer? _cooldownTick;

  bool get _isLoading => _action.isLoading;

  @override
  void initState() {
    super.initState();
    ref.read(passwordRecoveryCooldownProvider.notifier).clearExpiredLockIfNeeded();
    final cooldown = ref.read(passwordRecoveryCooldownProvider);
    if (cooldown.email case final email?) {
      _emailCtrl.text = email;
    }
    if (cooldown.isLocked) {
      _startCooldownTick();
    }
  }

  @override
  void dispose() {
    _cooldownTick?.cancel();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isLoading) return;

    final cooldown = ref.read(passwordRecoveryCooldownProvider);
    if (cooldown.isLocked) return;

    if (!validateAndSubmit()) return;

    final email = _emailCtrl.text.trim();
    setState(() => _action = const ActionLoading());
    try {
      await ref.read(authNotifierProvider.notifier).resetPassword(email);
      if (!mounted) return;

      ref
          .read(passwordRecoveryCooldownProvider.notifier)
          .onResendSuccess(email: email);
      _startCooldownTick();

      if (!mounted) return;
      setState(() => _action = const ActionIdle());
      context.go(
        AppRoutes.login,
        extra: LoginScreenNotice.recoveryEmailSent,
      );
    } catch (e) {
      await _showRecoveryErrorDialog(
        e is AppException ? e.message : 'Erro ao enviar. Tente novamente.',
      );
    }
  }

  Future<void> _showRecoveryErrorDialog(String message) async {
    if (!mounted) return;
    setState(() => _action = const ActionIdle());
    await AppFeedback.showError(
      context,
      title: 'Falha ao enviar link',
      message: message,
    );
  }

  void _startCooldownTick() {
    _cooldownTick?.cancel();
    _cooldownTick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      ref.read(passwordRecoveryCooldownProvider.notifier).clearExpiredLockIfNeeded();
      if (!ref.read(passwordRecoveryCooldownProvider).isLocked) {
        _cooldownTick?.cancel();
      }
      setState(() {});
    });
  }

  String _helperMessage(ResendCooldownState cooldown) {
    if (cooldown.isLocked) {
      return 'Ja enviamos um link recentemente para este e-mail.\n\n'
          'Para sua seguranca, aguarde alguns minutos antes de solicitar outro.';
    }

    return 'Se nao encontrar o e-mail, confira sua caixa de entrada e spam.'
        '\n\nQuando quiser, voce pode solicitar um novo link abaixo.';
  }

  @override
  Widget build(BuildContext context) {
    final cooldown = ref.watch(passwordRecoveryCooldownProvider);
    final isEmailLocked = cooldown.isLocked;
    final canResend = !_isLoading && !cooldown.isLocked;

    return AuthScaffold(
      padding: EdgeInsets.zero,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.primaryBackground,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios,
                    color: AppColors.tertiary,
                    size: 20,
                  ),
                  onPressed: _isLoading ? null : () => context.go(AppRoutes.login),
                ),
              ),
              const SizedBox(height: 60),
              Text(
                'Esqueceu sua senha?',
                textAlign: TextAlign.center,
                style: AppTextStyles.headlineSmall.copyWith(
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                isEmailLocked
                    ? 'O reenvio esta temporariamente bloqueado. Assim que o tempo terminar, voce podera solicitar um novo link.'
                    : 'Insira o seu e-mail abaixo que enviaremos um link para voce criar uma nova senha.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.actionBlue,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: 'Email',
                hint: 'Digite seu E-mail',
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.email],
                validator: emailValidator,
                readOnly: _isLoading || isEmailLocked,
                enabled: !_isLoading && !isEmailLocked,
                onFieldSubmitted: (_) {
                  if (!_isLoading && !cooldown.isLocked) _submit();
                },
              ),
              if (cooldown.hasStoredLock) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.alternate,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.actionBlue.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              isEmailLocked
                                  ? Icons.lock_clock_outlined
                                  : Icons.mark_email_read_outlined,
                              color: AppColors.actionBlue,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              isEmailLocked
                                  ? 'Reenvio disponivel em ${formatCooldownMmSs(cooldown.remainingLock)}'
                                  : 'Voce ja pode solicitar um novo link',
                              style: AppTextStyles.labelLarge.copyWith(
                                color: AppColors.secondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        _helperMessage(cooldown),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.secondaryText,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  SizedBox(
                    width: 135,
                    child: AppButton(
                      label: 'Voltar',
                      variant: AppButtonVariant.outlined,
                      onPressed:
                          _isLoading ? null : () => context.go(AppRoutes.login),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: cooldown.hasStoredLock
                        ? ResendCooldownButton(
                            cooldown: cooldown,
                            isLoading: _isLoading,
                            readyLabel: 'Reenviar link',
                            lockedLabelBuilder: (remaining) =>
                                'Reenviar em ${formatCooldownMmSs(remaining)}',
                            onPressed: canResend ? _submit : null,
                          )
                        : AppButton(
                            label: 'Enviar',
                            trailingIcon: const Icon(
                              Icons.send,
                              size: 16,
                              color: AppColors.secondaryBackground,
                            ),
                            onPressed: _isLoading ? null : _submit,
                            isLoading: _isLoading,
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
