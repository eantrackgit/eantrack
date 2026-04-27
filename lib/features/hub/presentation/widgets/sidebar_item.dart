part of 'menu_hub_sidebar.dart';

class _MenuHubSectionItem extends StatelessWidget {
  const _MenuHubSectionItem({
    required this.icon,
    required this.label,
    this.count,
    this.enabled = true,
    this.isDestructive = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final int? count;
  final bool enabled;
  final bool isDestructive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final et = EanTrackTheme.of(context);
    final iconColor = isDestructive
        ? AppColors.error
        : et.primaryText.withValues(alpha: 0.8);
    final textColor = isDestructive ? AppColors.error : et.primaryText;

    final row = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Icon(icon, size: 17, color: iconColor),
          const SizedBox(width: AppSpacing.sm),
          if (count != null) ...[
            Text(
              '$count',
              style: AppTextStyles.labelLarge.copyWith(
                color: textColor,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 4),
          ],
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (enabled)
            Icon(
              Icons.navigate_next,
              size: 18,
              color: et.secondaryText.withValues(alpha: 0.7),
            ),
        ],
      ),
    );

    final interactive = Material(
      color: Colors.transparent,
      child: InkWell(onTap: enabled ? onTap : null, child: row),
    );

    if (!enabled) {
      return Opacity(opacity: 0.45, child: interactive);
    }

    return interactive;
  }
}

class _MenuHubActionButton extends StatelessWidget {
  const _MenuHubActionButton({required this.label, this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final et = EanTrackTheme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: SizedBox(
        height: 34,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: et.primaryText,
            side: BorderSide(color: et.inputBorder),
            shape: RoundedRectangleBorder(borderRadius: AppRadius.smAll),
            padding: EdgeInsets.zero,
          ),
          child: Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: et.primaryText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuHubBillingRow extends StatelessWidget {
  const _MenuHubBillingRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      child: Row(
        children: [
          const Icon(
            Icons.receipt_outlined,
            size: 13,
            color: AppColors.success,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.success,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
