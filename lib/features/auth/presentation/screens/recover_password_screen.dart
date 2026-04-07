import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../shared/shared.dart';
import '../providers/auth_provider.dart';
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
    if (ref.read(passwordRecoveryCooldownProvider).isLocked) {
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

    setState(() => _action = const ActionLoading());
    try {
      await ref
          .read(authNotifierProvider.notifier)
          .resetPassword(_emailCtrl.text.trim());
      if (!mounted) return;

      ref.read(passwordRecoveryCooldownProvider.notifier).onResendSuccess();
      _startCooldownTick();

      await AppFeedback.showSuccess(
        context,
        title: 'Link enviado',
        message:
            'Enviamos um link para redefinir sua senha. Verifique sua caixa de entrada e spam. Por segurança, esse link expira em alguns minutos e pode ser usado apenas uma vez.',
        icon: Icons.mark_email_read_outlined,
      );

      if (!mounted) return;
      setState(() => _action = const ActionIdle());
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

  String _maskEmail(String email) {
    final parts = email.trim().split('@');
    if (parts.length != 2) return email.trim();

    final name = parts.first;
    final masked = name.length > 2 ? '${name.substring(0, 2)}**' : '**';
    return '$masked@${parts.last}';
  }

  String _helperMessage(ResendCooldownState cooldown) {
    if (cooldown.isLocked) {
      return 'Já enviamos um link recentemente.\n\n'
          'Para sua segurança, aguarde alguns minutos antes de solicitar outro.';
    }

    return 'Se não encontrar o e-mail, confira sua caixa de entrada e spam.'
        '\n\nQuando quiser, você pode solicitar um novo link abaixo.';
  }

  @override
  Widget build(BuildContext context) {
    final cooldown = ref.watch(passwordRecoveryCooldownProvider);
    final hasSentLink = cooldown.hasStoredLock;
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
                hasSentLink ? 'Link enviado com sucesso' : 'Esqueceu sua senha?',
                textAlign: TextAlign.center,
                style: AppTextStyles.headlineSmall.copyWith(
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                hasSentLink
                    ? 'Enviamos um link de recuperação para o e-mail informado.'
                    : 'Insira o seu e-mail abaixo que enviaremos um link para você criar uma nova senha.',
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
                readOnly: _isLoading,
                onFieldSubmitted: (_) {
                  if (!_isLoading && !cooldown.isLocked) _submit();
                },
              ),
              if (hasSentLink) ...[
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
                              'Último envio para ${_maskEmail(_emailCtrl.text)}',
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
                    child: hasSentLink
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
