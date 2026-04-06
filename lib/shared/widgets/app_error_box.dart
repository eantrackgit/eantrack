import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

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
