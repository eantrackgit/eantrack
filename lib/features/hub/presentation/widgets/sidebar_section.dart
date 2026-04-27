part of 'menu_hub_sidebar.dart';

class _MenuHubSection extends StatelessWidget {
  const _MenuHubSection({
    required this.icon,
    required this.title,
    required this.children,
    this.wrapInCard = true,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;
  final bool wrapInCard;

  @override
  Widget build(BuildContext context) {
    final et = EanTrackTheme.of(context);
    final childrenWidget = wrapInCard
        ? Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            decoration: BoxDecoration(
              color: et.cardSurface,
              borderRadius: AppRadius.mdAll,
              border: Border.all(
                color: et.surfaceBorder.withValues(alpha: 0.7),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          child: Row(
            children: [
              Icon(icon, size: 13, color: et.primaryText),
              const SizedBox(width: AppSpacing.xs),
              Text(
                title.toUpperCase(),
                style: AppTextStyles.labelSmall.copyWith(
                  color: et.primaryText,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
        childrenWidget,
        const SizedBox(height: AppSpacing.sm),
      ],
    );
  }
}
