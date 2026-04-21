import 'package:flutter/material.dart';

import '../shared.dart';

class NoConnectionView extends StatelessWidget {
  const NoConnectionView({
    super.key,
    this.isRetrying = false,
    this.onRetry,
  });

  final bool isRetrying;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final et = EanTrackTheme.of(context);

    return Material(
      color: et.scaffoldOuter.withValues(alpha: 0.96),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: et.cardSurface,
                borderRadius: AppRadius.lgAll,
                border: Border.all(color: et.surfaceBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.wifi_off_rounded,
                      size: 72,
                      color: AppColors.actionBlue,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Sem Conexão',
                      style: AppTextStyles.headlineSmall.copyWith(
                        color: et.primaryText,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Verifique sua conexão com a internet e tente novamente',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: et.secondaryText,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (isRetrying) ...[
                      const SizedBox(height: AppSpacing.lg),
                      const Center(child: CircularProgressIndicator()),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                    AppButton.primary(
                      'Tentar novamente',
                      isLoading: isRetrying,
                      onPressed: isRetrying ? null : onRetry,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
