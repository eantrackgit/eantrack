import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'app_button.dart';

Future<void> showAppFeedbackDialog({
  required BuildContext context,
  required String title,
  required String message,
  IconData icon = Icons.info_outline_rounded,
  Color accentColor = AppColors.secondary,
  bool dismissible = true,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: dismissible,
    barrierColor: Colors.transparent,
    builder: (dialogContext) {
      return Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: dismissible
                    ? () => Navigator.of(dialogContext).pop()
                    : null,
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ColoredBox(
                          color:
                              AppColors.modalOverlayBase.withValues(alpha: 0.52),
                        ),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.modalOverlayMid
                                    .withValues(alpha: 0.92),
                                AppColors.modalOverlayBase
                                    .withValues(alpha: 0.84),
                                AppColors.modalOverlayGlow
                                    .withValues(alpha: 0.22),
                              ],
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.topRight,
                          child: IgnorePointer(
                            child: Container(
                              width: 320,
                              height: 320,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    AppColors.modalOverlayGlow
                                        .withValues(alpha: 0.18),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.xl,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryBackground,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: accentColor.withValues(alpha: 0.14),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.modalOverlayBase
                                .withValues(alpha: 0.28),
                            blurRadius: 32,
                            offset: const Offset(0, 18),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Align(
                            alignment: Alignment.topRight,
                            child: IconButton(
                              onPressed: () => Navigator.of(dialogContext).pop(),
                              visualDensity: VisualDensity.compact,
                              splashRadius: 20,
                              icon: Icon(
                                Icons.close_rounded,
                                color: AppColors.secondaryText
                                    .withValues(alpha: 0.8),
                              ),
                            ),
                          ),
                          Container(
                            width: 72,
                            height: 72,
                            margin: const EdgeInsets.only(bottom: AppSpacing.md),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: accentColor.withValues(alpha: 0.1),
                            ),
                            child: Icon(
                              icon,
                              size: 34,
                              color: accentColor,
                            ),
                          ),
                          Text(
                            title,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.headlineSmall.copyWith(
                              color: AppColors.secondary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            message,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.secondaryText,
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          AppButton(
                            label: 'Entendi',
                            onPressed: () => Navigator.of(dialogContext).pop(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}
