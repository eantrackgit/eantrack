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

class AppErrorBox extends StatefulWidget {
  const AppErrorBox(this.message, {super.key});

  final String message;

  @override
  State<AppErrorBox> createState() => _AppErrorBoxState();
}

class _AppErrorBoxState extends State<AppErrorBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shakeCtrl;
  late final Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _shakeAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 7.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 7.0, end: -7.0), weight: 30),
      TweenSequenceItem(tween: Tween(begin: -7.0, end: 4.0), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 4.0, end: 0.0), weight: 25),
    ]).animate(
      CurvedAnimation(parent: _shakeCtrl, curve: Curves.easeInOut),
    );
    _shakeCtrl.forward();
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shakeAnim,
      builder: (_, child) => Transform.translate(
        offset: Offset(_shakeAnim.value, 0),
        child: child,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSpacing.sm),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 18),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                widget.message,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.error,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PasswordRuleRow extends StatelessWidget {
  const PasswordRuleRow({
    super.key,
    required this.satisfied,
    required this.label,
    required this.isTyping,
  });

  final bool satisfied;
  final String label;
  final bool isTyping;

  @override
  Widget build(BuildContext context) {
    final Color color;
    final IconData icon;

    if (!isTyping) {
      color = AppColors.accent2;
      icon = Icons.radio_button_unchecked;
    } else if (satisfied) {
      color = AppColors.success;
      icon = Icons.check_circle;
    } else {
      color = AppColors.error;
      icon = Icons.cancel;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            switchInCurve: Curves.easeInOut,
            switchOutCurve: Curves.easeInOut,
            transitionBuilder: (child, anim) => ScaleTransition(
              scale: anim,
              child: FadeTransition(opacity: anim, child: child),
            ),
            child: Icon(icon, key: ValueKey(icon), size: 14, color: color),
          ),
          const SizedBox(width: 6),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeInOut,
            style: AppTextStyles.labelSmall.copyWith(color: color),
            child: Text(label),
          ),
        ],
      ),
    );
  }
}
