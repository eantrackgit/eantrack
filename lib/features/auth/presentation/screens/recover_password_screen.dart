import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../shared/shared.dart';
import '../providers/auth_provider.dart';

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

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!validateAndSubmit()) return;
    setState(() => _action = const ActionLoading());
    try {
      await ref
          .read(authNotifierProvider.notifier)
          .resetPassword(_emailCtrl.text.trim());
      if (!mounted) return;
      setState(() => _action = const ActionSuccess(null));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Link enviado! Verifique sua caixa de entrada.'),
        ),
      );
      context.go(AppRoutes.login);
    } catch (e) {
      if (!mounted) return;
      setState(() => _action = ActionFailure(
            e is AppException ? e.message : 'Erro ao enviar. Tente novamente.',
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      isLoading: _action.isLoading,
      loadingMessage: 'Enviando e-mail...',
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
                  onPressed: () => context.go(AppRoutes.login),
                ),
              ),
              const SizedBox(height: 60),
              Text(
                'Esqueceu sua senha?',
                textAlign: TextAlign.center,
                style: AppTextStyles.headlineSmall
                    .copyWith(color: AppColors.secondary),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Insira o seu e-mail abaixo que enviaremos um link '
                'para você criar uma nova senha.',
                textAlign: TextAlign.center,
                style:
                    AppTextStyles.bodySmall.copyWith(color: AppColors.actionBlue),
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
                onFieldSubmitted: (_) {
                  if (!_action.isLoading) _submit();
                },
              ),
              if (_action.isFailure) ...[
                const SizedBox(height: AppSpacing.sm),
                AppErrorBox(_action.errorMessage!),
              ],
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  SizedBox(
                    width: 135,
                    child: AppButton(
                      label: 'Voltar',
                      variant: AppButtonVariant.outlined,
                      onPressed: _action.isLoading
                          ? null
                          : () => context.go(AppRoutes.login),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: AppButton(
                      label: 'Enviar',
                      trailingIcon: const Icon(
                        Icons.send,
                        size: 16,
                        color: AppColors.info,
                      ),
                      onPressed: _action.isLoading ? null : _submit,
                      isLoading: _action.isLoading,
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
