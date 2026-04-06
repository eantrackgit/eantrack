import 'package:flutter/material.dart';

import '../../core/config/app_version.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

class AppVersionBadge extends StatelessWidget {
  const AppVersionBadge({
    super.key,
    this.alignment = Alignment.center,
    this.textColor = AppColors.secondaryText,
  });

  final Alignment alignment;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: textColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        child: Text(
          AppVersion.label,
          style: AppTextStyles.labelSmall.copyWith(
            color: textColor.withValues(alpha: 0.9),
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}
