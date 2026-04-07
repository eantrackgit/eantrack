import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;

import '../../../../core/router/app_routes.dart';
import '../../../../shared/shared.dart';
import '../../domain/auth_state.dart';
import '../providers/auth_provider.dart';
import '../widgets/resend_cooldown_button.dart';

class EmailVerificationScreen extends ConsumerStatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  ConsumerState<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends ConsumerState<EmailVerificationScreen> {
  Timer? _cooldownTick;

  bool _confirmed = false;
  bool _navigating = false;
  bool _resendLoading = false;
  bool _isManualChecking = false;
  String _email = '';

  @override
  void initState() {
    super.initState();

    final s = ref.read(authNotifierProvider);
    if (s is AuthEmailUnconfirmed) {
      _email = s.email;
    }

    if (ref.read(emailCooldownProvider).isLocked) {
      _startCooldownTick();
    }
  }

  @override
  void dispose() {
    _cooldownTick?.cancel();
    super.dispose();
  }

  void _navigate() {
    if (_navigating) return;
    _navigating = true;
    context.go(AppRoutes.flow);
  }

  // ---------------------------------------------------------------------------
  // Password modal — opened after confirmation detected
  // ---------------------------------------------------------------------------

  Future<void> _openPasswordModal() async {
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (_) => _PasswordModal(email: _email, onSuccess: _navigate),
    );
  }

  // ---------------------------------------------------------------------------
  // Resend / manual check
  // ---------------------------------------------------------------------------

  Future<void> _resend() async {
    if (_email.isEmpty) {
      await _showFeedbackDialog(
        title: 'E-mail indisponível',
        message: 'Volte e tente novamente.',
        icon: Icons.mail_outline_rounded,
        accentColor: AppColors.error,
      );
      return;
    }
    final cooldown = ref.read(emailCooldownProvider);
    if (cooldown.isLocked) return;
    if (cooldown.hasReachedAttemptLimit) {
      await _showFeedbackDialog(
        title: 'Limite atingido',
        message: 'Você excedeu o número de tentativas. Tente mais tarde.',
        icon: Icons.schedule_rounded,
        accentColor: AppColors.error,
      );
      return;
    }
    setState(() => _resendLoading = true);
    try {
      final alreadyConfirmed =
          await ref.read(authNotifierProvider.notifier).checkEmailConfirmed();
      if (!mounted) return;
      if (alreadyConfirmed) {
        setState(() => _resendLoading = false);
        setState(() => _confirmed = true);
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) _openPasswordModal();
        return;
      }
      final sent =
          await ref.read(authNotifierProvider.notifier).resendVerificationEmail();
      if (!mounted) return;
      setState(() => _resendLoading = false);
      if (!sent) {
        await _showFeedbackDialog(
          title: 'Falha ao reenviar',
          message: 'Tente novamente.',
          icon: Icons.error_outline_rounded,
          accentColor: AppColors.error,
        );
        return;
      }
      ref.read(emailCooldownProvider.notifier).onResendSuccess();
      await _showFeedbackDialog(
        title: 'Link enviado',
        message:
            'Enviamos um link para redefinir sua senha. Verifique sua caixa de entrada e spam. Por segurança, esse link expira em alguns minutos e pode ser usado apenas uma vez.',
        icon: Icons.mark_email_read_outlined,
        accentColor: AppColors.success,
      );
      if (!mounted) return;
      _startCooldownTick();
    } catch (_) {
      if (!mounted) return;
      setState(() => _resendLoading = false);
      await _showFeedbackDialog(
        title: 'Falha ao reenviar',
        message: 'Tente novamente.',
        icon: Icons.error_outline_rounded,
        accentColor: AppColors.error,
      );
    }
  }

  Future<void> _checkNow() async {
    if (_isManualChecking) return;
    setState(() => _isManualChecking = true);
    try {
      final ok =
          await ref.read(authNotifierProvider.notifier).checkEmailConfirmed();
      if (!mounted) return;
      if (ok && !_navigating) {
        setState(() {
          _confirmed = true;
          _isManualChecking = false;
        });
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) _openPasswordModal();
      } else {
        setState(() => _isManualChecking = false);
        if (!ok) {
          await _showFeedbackDialog(
            title: 'E-mail ainda não confirmado',
            message: 'Verifique sua caixa de entrada e tente novamente.',
            icon: Icons.mark_email_unread_outlined,
            accentColor: AppColors.secondary,
          );
        }
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isManualChecking = false);
      await _showFeedbackDialog(
        title: 'Erro ao verificar',
        message: 'Tente novamente.',
        icon: Icons.error_outline_rounded,
        accentColor: AppColors.error,
      );
    }
  }

  void _startCooldownTick() {
    _cooldownTick?.cancel();
    _cooldownTick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (!ref.read(emailCooldownProvider).isLocked) _cooldownTick?.cancel();
      setState(() {});
    });
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Future<void> _showFeedbackDialog({
    required String title,
    required String message,
    IconData icon = Icons.info_outline_rounded,
    Color accentColor = AppColors.secondary,
  }) {
    return showAppFeedbackDialog(
      context: context,
      title: title,
      message: message,
      icon: icon,
      accentColor: accentColor,
    );
  }

  String _censor(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return email;
    final name = parts[0];
    final masked = name.length > 2 ? '${name.substring(0, 2)}**' : '**';
    return '$masked@${parts[1]}';
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final cooldown = ref.watch(emailCooldownProvider);
    final canResend = !cooldown.isLocked && !_resendLoading;

    return AuthScaffold(
      child: _confirmed
          ? _buildConfirmed()
          : _buildWaiting(cooldown, canResend),
    );
  }

  // ---------------------------------------------------------------------------
  // Waiting state
  // ---------------------------------------------------------------------------

  Widget _buildWaiting(ResendCooldownState cooldown, bool canResend) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.md),

        // Logo
        Center(
          child: SvgPicture.asset(
            'assets/images/eantrack.svg',
            width: 160,
            height: 70,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Title
        Text(
          'Confirme sua conta',
          style: AppTextStyles.headlineSmall
              .copyWith(color: AppColors.secondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.md),

        // Info box
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.primaryBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.secondaryText),
              children: [
                const TextSpan(
                    text:
                        'Verifique seu e-mail, um link de confirmação foi enviado para '),
                TextSpan(
                  text: _censor(_email),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const TextSpan(
                    text:
                        '. Clique em confirmar sua conta para começar a usar o '),
                TextSpan(
                  text: 'EANTrack',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Buttons row
        Row(
          children: [
            SizedBox(
              width: 120,
              child: AppButton(
                label: 'Voltar',
                variant: AppButtonVariant.outlined,
                leadingIcon: const Icon(
                  Icons.arrow_back_ios,
                  size: 14,
                  color: AppColors.secondary,
                ),
                onPressed: () => context.go(AppRoutes.login),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: ResendCooldownButton(
                readyLabel: 'Reenviar',
                cooldown: cooldown,
                isLoading: _resendLoading,
                lockedLabelBuilder: (remaining) =>
                    'Aguarde... ${formatCooldownMmSs(remaining)}',
                onPressed: canResend ? _resend : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        // Manual check CTA
        Center(
          child: TextButton(
            onPressed: _isManualChecking ? null : _checkNow,
            child: _isManualChecking
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.secondaryText,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Verificando...',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.secondaryText),
                      ),
                    ],
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Já confirmei meu e-mail',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.secondaryText),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_forward,
                        size: 14,
                        color: AppColors.secondaryText,
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Confirmed state (shown briefly before modal opens)
  // ---------------------------------------------------------------------------

  Widget _buildConfirmed() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.xl),

        Center(
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.success, width: 3),
            ),
            child: const Icon(
              Icons.check,
              size: 48,
              color: AppColors.success,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        Text(
          'E-mail confirmado!',
          style: AppTextStyles.headlineSmall.copyWith(color: AppColors.success),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),

        Center(
          child: Text(
            'Confirme sua identidade para continuar',
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.secondaryText),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

// =============================================================================
// Password Modal — shown after email confirmation
// =============================================================================

class _PasswordModal extends ConsumerStatefulWidget {
  const _PasswordModal({required this.email, required this.onSuccess});

  final String email;
  final VoidCallback onSuccess;

  @override
  ConsumerState<_PasswordModal> createState() => _PasswordModalState();
}

class _PasswordModalState extends ConsumerState<_PasswordModal> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    final password = _controller.text.trim();
    if (password.isEmpty) {
      setState(() => _error = 'Digite sua senha para continuar.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authNotifierProvider.notifier).signInAfterConfirmation(
            email: widget.email,
            password: password,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onSuccess();
    } on AuthException catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Senha incorreta. Verifique e tente novamente.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error =
            'Erro de conexão. Verifique sua internet e tente novamente.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.secondaryBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg + bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.alternate,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Icon + title
          Center(
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.secondary.withValues(alpha: 0.08),
              ),
              child: const Icon(
                Icons.lock_outline_rounded,
                size: 28,
                color: AppColors.secondary,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          Text(
            'Confirme seu acesso',
            style: AppTextStyles.headlineSmall
                .copyWith(color: AppColors.secondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),

          Text(
            'Seu e-mail foi confirmado. Digite sua senha para entrar.',
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.secondaryText),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),

          // Password field
          TextField(
            controller: _controller,
            focusNode: _focusNode,
            obscureText: _obscure,
            onSubmitted: (_) => _confirm(),
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.secondary),
            decoration: InputDecoration(
              hintText: 'Senha',
              hintStyle: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.secondaryText,
              ),
              filled: true,
              fillColor: AppColors.primaryBackground,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.alternate),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.alternate),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppColors.secondary, width: 1.5),
              ),
              errorText: _error,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscure ? Icons.visibility_off : Icons.visibility,
                  color: AppColors.secondaryText,
                  size: 20,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Confirm button
          SizedBox(
            height: 52,
            child: AppButton(
              label: 'Entrar',
              isLoading: _loading,
              onPressed: _loading ? null : _confirm,
              trailingIcon: _loading
                  ? null
                  : const Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: AppColors.info,
                    ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Center(
            child: TextButton(
              onPressed: _loading
                  ? null
                  : () {
                      Navigator.of(context).pop();
                      context.go(AppRoutes.recoverPassword);
                    },
              child: Text(
                'Esqueceu sua senha?',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.actionBlue,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}

