import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Wraps a widget and shows a semi-transparent loading overlay when [isLoading].
class AppLoadingOverlay extends StatelessWidget {
  const AppLoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
  });

  final bool isLoading;
  final Widget child;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Positioned.fill(
            child: ColoredBox(
              color: Colors.black54,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Lottie.asset(
                    'assets/jsons/Insider-loading.json',
                    width: 120,
                    height: 120,
                  ),
                  if (message != null && message!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      message!,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.info,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Standalone centered loading indicator (use inside Scaffold body).
class AppLoadingIndicator extends StatelessWidget {
  const AppLoadingIndicator({super.key, this.message});
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Lottie.asset('assets/jsons/Insider-loading.json', width: 120),
          if (message != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(message!, style: AppTextStyles.bodyMedium),
            ),
        ],
      ),
    );
  }
}
