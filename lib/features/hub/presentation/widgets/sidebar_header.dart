part of 'menu_hub_sidebar.dart';

class _MenuHubUserHeader extends StatelessWidget {
  const _MenuHubUserHeader({
    required this.userName,
    required this.userRole,
    required this.agencyName,
    this.avatarUrl,
  });

  final String userName;
  final String userRole;
  final String agencyName;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final et = EanTrackTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          color: et.inputFill,
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: et.ctaBackground.withValues(alpha: 0.18),
                backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
                child: avatarUrl == null
                    ? Icon(Icons.person_rounded, size: 22, color: et.ctaBackground)
                    : null,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: AppTextStyles.labelLarge.copyWith(
                        color: et.primaryText,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    Text(
                      userRole,
                      style: AppTextStyles.labelSmall.copyWith(color: et.secondaryText),
                    ),
                    if (agencyName.isNotEmpty)
                      Text(
                        agencyName,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.actionBlue,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: et.divider),
      ],
    );
  }
}

class _MenuHubIdentityCard extends StatelessWidget {
  const _MenuHubIdentityCard({
    required this.agencyName,
    required this.agencyHandle,
    this.logoUrl,
    this.onEditAgency,
  });

  final String agencyName;
  final String agencyHandle;
  final String? logoUrl;
  final VoidCallback? onEditAgency;

  String get _handle =>
      agencyHandle.startsWith('@') ? agencyHandle : '@$agencyHandle';

  @override
  Widget build(BuildContext context) {
    final et = EanTrackTheme.of(context);

    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.xs,
        AppSpacing.sm,
        AppSpacing.xs,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF0E0A36)
            : et.inputFill,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: et.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: et.inputFill,
                backgroundImage: logoUrl != null ? NetworkImage(logoUrl!) : null,
                child: logoUrl == null
                    ? Icon(Icons.support_agent_rounded, size: 26, color: et.secondaryText)
                    : null,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      agencyName,
                      style: AppTextStyles.labelLarge.copyWith(
                        color: et.primaryText,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    Text(
                      _handle,
                      style: AppTextStyles.labelSmall.copyWith(color: et.secondaryText),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 34,
            child: OutlinedButton(
              onPressed: onEditAgency,
              style: OutlinedButton.styleFrom(
                backgroundColor: et.inputFill,
                foregroundColor: et.primaryText,
                side: BorderSide(color: et.inputBorder),
                shape: RoundedRectangleBorder(borderRadius: AppRadius.smAll),
                padding: EdgeInsets.zero,
              ),
              child: Text(
                'Editar Agência',
                style: AppTextStyles.labelSmall.copyWith(
                  color: et.primaryText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Text(
                'Powered by ',
                style: AppTextStyles.labelSmall.copyWith(color: et.secondaryText),
              ),
              Text(
                'EANTrack',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.actionBlue,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
