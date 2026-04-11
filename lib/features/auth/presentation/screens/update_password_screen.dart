import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../shared/shared.dart';
import '../providers/auth_provider.dart';

class UpdatePasswordScreen extends ConsumerStatefulWidget {
  const UpdatePasswordScreen({super.key});

  @override
  ConsumerState<UpdatePasswordScreen> createState() =>
      _UpdatePasswordScreenState();
}

class _UpdatePasswordScreenState
    extends ConsumerState<UpdatePasswordScreen>
    with FormStateMixin<UpdatePasswordScreen> {
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _confirmFocus = FocusNode();
  AsyncAction<void> _action = const ActionIdle();

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  bool get _canSubmit => passwordValid && passwordsMatch;

  Future<void> _submit() async {
    if (!validateAndSubmit()) return;
    if (!_canSubmit || _action.isLoading) return;
    setState(() => _action = const ActionLoading());
    try {
      await ref.read(authRepositoryProvider).changePassword(_passwordCtrl.text);
      if (!mounted) return;
      setState(() => _action = const ActionSuccess(null));
      await AppFeedback.showSuccess(
        context,
        title: 'Senha alterada',
        message:
            'Sua senha foi atualizada com sucesso. Faça login novamente para continuar.',
      );
      if (!mounted) return;
      await ref.read(authNotifierProvider.notifier).signOut();
      return;
    } on SamePasswordException catch (e) {
      await _showUpdatePasswordErrorDialog(e.message);
    } on AppException catch (e) {
      await _showUpdatePasswordErrorDialog(e.message);
    } catch (_) {
      await _showUpdatePasswordErrorDialog(
        'Erro ao atualizar senha. Tente novamente.',
      );
    }
  }

  Future<void> _showUpdatePasswordErrorDialog(String message) async {
    if (!mounted) return;
    setState(() => _action = const ActionIdle());
    await AppFeedback.showError(
      context,
      title: 'Falha ao atualizar senha',
      message: message,
    );
  }

  @override
  Widget build(BuildContext context) {
    final et = EanTrackTheme.of(context);

    return AuthScaffold(
      showLogo: true,
      title: 'Defina sua nova senha',
      subtitle: 'Digite abaixo a nova senha',
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              label: 'Senha',
              hint: 'Digite sua Senha',
              controller: _passwordCtrl,
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
                  label: 'Uma letra maiúscula',
                  isTyping: isTypingPassword,
                ),
                PasswordRuleRow(
                  satisfied: hasLowercase,
                  label: 'Uma letra minúscula',
                  isTyping: isTypingPassword,
                ),
                PasswordRuleRow(
                  satisfied: hasDigit,
                  label: 'Um número',
                  isTyping: isTypingPassword,
                ),
                PasswordRuleRow(
                  satisfied: hasMinLength,
                  label: 'Mínimo de 8 caracteres',
                  isTyping: isTypingPassword,
                ),
                PasswordRuleRow(
                  satisfied: hasSymbol,
                  label: 'Um símbolo (ex: @, #, \$, %, &, *)',
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
              label: 'Confirmar Senha',
              hint: 'Digite sua Senha',
              controller: _confirmCtrl,
              focusNode: _confirmFocus,
              isPassword: true,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.newPassword],
              validator: (value) => confirmValidator(value, _passwordCtrl),
              onChanged: (value) => onConfirmChanged(value, _passwordCtrl),
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                SizedBox(
                  width: 120,
                  child: AppButton(
                    label: 'Voltar',
                    variant: AppButtonVariant.outlined,
                    leadingIcon: const Icon(Icons.arrow_back_ios, size: 14),
                    onPressed: _action.isLoading
                        ? null
                        : () => context.go(AppRoutes.login),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppButton(
                    label: 'Alterar',
                    isLoading: _action.isLoading,
                    onPressed: _canSubmit && !_action.isLoading ? _submit : null,
                    trailingIcon: _action.isLoading
                        ? null
                        : Icon(
                            Icons.arrow_forward_ios,
                            size: 14,
                            color: et.ctaForeground,
                          ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }
}
