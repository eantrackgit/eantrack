import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'app_card.dart';
import 'app_version_badge.dart';

/// Standard layout for auth and onboarding screens.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.showLogo = false,
    this.logoWidth = 180,
    this.logoHeight = 60,
    this.padding,
  });

  final Widget child;
  final String? title;
  final String? subtitle;
  final bool showLogo;
  final double logoWidth;
  final double logoHeight;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: AppCard(
                color: AppColors.secondaryBackground,
                padding: padding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (showLogo) ...[
                      Center(
                        child: SvgPicture.asset(
                          'assets/images/eantrack.svg',
                          width: logoWidth,
                          height: logoHeight,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                    if (title != null) ...[
                      Text(
                        title!,
                        style: AppTextStyles.headlineSmall.copyWith(
                          color: AppColors.secondary,
                        ),
                        textAlign:
                            showLogo ? TextAlign.center : TextAlign.start,
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          subtitle!,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.secondaryText,
                          ),
                          textAlign:
                              showLogo ? TextAlign.center : TextAlign.start,
                        ),
                      ],
                      const SizedBox(height: AppSpacing.lg),
                    ],
                    child,
                    const SizedBox(height: AppSpacing.lg),
                    const AppVersionBadge(),
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

