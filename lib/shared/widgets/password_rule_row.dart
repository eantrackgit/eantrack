import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';

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
      color = EanTrackTheme.of(context).secondaryText;
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
          Expanded(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeInOut,
              style: AppTextStyles.labelSmall.copyWith(color: color),
              child: Text(label),
            ),
          ),
        ],
      ),
    );
  }
}
