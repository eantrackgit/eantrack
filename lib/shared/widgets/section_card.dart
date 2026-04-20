import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';

/// Card de seção padronizado com título em caixa alta e borda sutil.
///
/// Usado nas telas de onboarding para agrupar visualmente conjuntos de campos
/// relacionados (dados fiscais, contato, documentos etc.).
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final et = EanTrackTheme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: et.surface.withValues(alpha: 0.55),
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: et.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: AppTextStyles.labelMedium.copyWith(
              color: et.primaryText,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }
}
