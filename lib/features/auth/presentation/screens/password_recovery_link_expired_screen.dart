import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../shared/shared.dart';

class PasswordRecoveryLinkExpiredScreen extends StatelessWidget {
  const PasswordRecoveryLinkExpiredScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final et = EanTrackTheme.of(context);

    return AuthScaffold(
      showLogo: true,
      title: 'Link expirado',
      subtitle:
          'Esse link de recuperação não é mais válido. Solicite um novo link para redefinir sua senha.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.md),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.error.withValues(alpha: 0.12),
                  et.ctaBackground.withValues(alpha: 0.08),
                ],
              ),
              border: Border.all(
                color: AppColors.error.withValues(alpha: 0.18),
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.error.withValues(alpha: 0.12),
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Icon(
                    Icons.link_off_rounded,
                    size: 32,
                    color: et.ctaForeground,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Por segurança, links de redefinição só podem ser usados dentro do prazo e uma única vez.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: et.primaryText,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Volte ao login para solicitar um novo link.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: et.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: 'Voltar ao login',
            onPressed: () => context.go(AppRoutes.login),
            leadingIcon: Icon(
              Icons.arrow_back_ios_new,
              size: 14,
              color: et.ctaForeground,
            ),
          ),
        ],
      ),
    );
  }
}
