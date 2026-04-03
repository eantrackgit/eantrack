import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../shared/shared.dart';

class IndividualPlaceholderScreen extends StatelessWidget {
  const IndividualPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Modo Individual em breve',
                  style: AppTextStyles.headlineSmall.copyWith(
                    color: AppColors.info,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: 180,
                  child: AppButton(
                    label: 'Voltar',
                    onPressed: () => context.go(AppRoutes.login),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
