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
    final comfortable = _MenuHubLayout.comfortableOf(context);
    final iconColor = isDestructive
        ? AppColors.error
        : et.primaryText.withValues(alpha: 0.8);
    final textColor = isDestructive ? AppColors.error : et.primaryText;

    // Item de submenu confortável: fonte maior (15sp / w600) e área de toque
    // ampla, quase do tamanho do título do grupo mas mantendo hierarquia.
    final labelStyle = comfortable
        ? AppTextStyles.bodyMedium.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: textColor,
          )
        : AppTextStyles.bodySmall.copyWith(
            fontWeight: FontWeight.w500,
            color: textColor,
          );

    final row = ConstrainedBox(
      // Confortável (desktop + mobile) ganha altura/área de toque maior
      // (>= 56px); compacto mantém o tamanho mínimo legado.
      constraints: BoxConstraints(minHeight: comfortable ? 56 : 0),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: comfortable ? 18 : AppSpacing.md,
          vertical: comfortable ? 12 : AppSpacing.sm,
        ),
        child: Row(
          children: [
            Icon(icon, size: comfortable ? 21 : 17, color: iconColor),
            SizedBox(width: comfortable ? 14 : AppSpacing.sm),
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
                style: labelStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (enabled)
              Icon(
                Icons.navigate_next,
                size: comfortable ? 20 : 18,
                color: et.secondaryText.withValues(alpha: 0.7),
              ),
          ],
        ),
      ),
    );

    final interactive = Material(
      color: Colors.transparent,
      child: InkWell(onTap: enabled ? onTap : null, child: row),
    );

    return Opacity(
      opacity: enabled ? 1.0 : 0.45,
      child: interactive,
    );
  }
}

class _MenuHubActionButton extends StatelessWidget {
  const _MenuHubActionButton({required this.label, this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final et = EanTrackTheme.of(context);
    final comfortable = _MenuHubLayout.comfortableOf(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        comfortable ? 18 : AppSpacing.md,
        AppSpacing.xs,
        comfortable ? 18 : AppSpacing.md,
        AppSpacing.sm,
      ),
      child: SizedBox(
        height: comfortable ? 46 : 34,
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
