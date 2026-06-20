import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/router/recovery_link_parser.dart';
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
              color: et.surface,
              borderRadius: BorderRadius.circular(AppSpacing.md),
              border: Border.all(
                color: AppColors.error.withValues(alpha: 0.22),
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
                  child: const Icon(
                    Icons.link_off_rounded,
                    size: 32,
                    color: AppColors.error,
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
            // replace (nao go): tira esta tela do historico para que "voltar"
            // no navegador nao reabra o LinkExpired em loop. Limpa tambem a
            // justificativa de sessao para que uma URL antiga/digitada a mao
            // para esta tela nao volte a funcionar depois do login.
            onPressed: () {
              RecoveryLinkParser.clearExpiredLinkJustification();
              context.replace(AppRoutes.login);
            },
            leadingIcon: const Icon(
              Icons.arrow_back_ios_new,
              size: 14,
            ),
          ),
        ],
      ),
    );
  }
}
