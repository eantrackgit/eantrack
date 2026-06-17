part of 'menu_hub_sidebar.dart';

/// Drawer lateral do Hub para o layout mobile.
///
/// Reaproveita o mesmo conteúdo (header + seções + rodapé) da
/// [MenuHubSidebar] de desktop através de [_MenuHubSidebarBody], mantendo
/// uma única fonte para os itens de menu do Hub.
class MobileHubDrawer extends ConsumerWidget {
  const MobileHubDrawer({
    super.key,
    required this.userName,
    required this.userRole,
    required this.agencyName,
    required this.agencyHandle,
    this.userAvatarUrl,
    this.agencyLogoUrl,
    required this.agencyStatus,
    required this.onSignOut,
    this.onEditAgency,
    this.onManageInvites,
    this.onManagePlan,
    this.activesCount = 0,
    this.sentInvitesCount = 0,
    this.pendingInvitesCount = 0,
    this.planName = 'Plano Profissional',
    this.nextBillingText = '',
  });

  final String userName;
  final String userRole;
  final String agencyName;
  final String agencyHandle;
  final String? userAvatarUrl;
  final String? agencyLogoUrl;
  final AgencyDocumentStatus agencyStatus;
  final VoidCallback onSignOut;
  final VoidCallback? onEditAgency;
  final VoidCallback? onManageInvites;
  final VoidCallback? onManagePlan;
  final int activesCount;
  final int sentInvitesCount;
  final int pendingInvitesCount;
  final String planName;
  final String nextBillingText;

  bool _isBlocked(AgencyStatusData? data) {
    final effectiveAgencyStatus = data?.statusAgency ?? agencyStatus;
    final effectiveDocumentStatus =
        data?.consolidatedDocumentStatus ?? agencyStatus;
    final termsAccepted = data?.termsAccepted ?? false;

    return effectiveAgencyStatus != AgencyDocumentStatus.approved ||
        effectiveDocumentStatus != AgencyDocumentStatus.approved ||
        !termsAccepted;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final et = EanTrackTheme.of(context);
    final provider = agencyStatusProvider(null);
    final statusState = ref.watch(provider);
    final isBlocked = _isBlocked(statusState.data);

    if (statusState.status == AgencyStatusLoading.idle) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        ref.read(provider.notifier).load();
      });
    }

    return Drawer(
      backgroundColor: et.sidebarSurface,
      child: SafeArea(
        child: _MenuHubSidebarBody(
          userName: userName,
          userRole: userRole,
          agencyName: agencyName,
          agencyHandle: agencyHandle,
          userAvatarUrl: userAvatarUrl,
          agencyLogoUrl: agencyLogoUrl,
          isBlocked: isBlocked,
          onEditAgency: onEditAgency,
          onSignOut: onSignOut,
          onManageInvites: onManageInvites,
          onManagePlan: onManagePlan,
          activesCount: activesCount,
          sentInvitesCount: sentInvitesCount,
          pendingInvitesCount: pendingInvitesCount,
          planName: planName,
          nextBillingText: nextBillingText,
          showMobileProfileHeader: true,
        ),
      ),
    );
  }
}

/// Topo exclusivo do drawer mobile: rótulo "Menu" + fechar, seguido de uma
/// barra discreta de identidade (avatar com inicial, nome, agência, cargo).
/// Substitui o [_MenuHubUserHeader] só aqui -- desktop continua com o
/// header original (ver showMobileProfileHeader em _MenuHubSidebarBody).
class _MobileDrawerTopBar extends StatelessWidget {
  const _MobileDrawerTopBar({
    required this.userName,
    required this.userRole,
    required this.agencyName,
    this.avatarUrl,
  });

  final String userName;
  final String userRole;
  final String agencyName;
  final String? avatarUrl;

  static const _fallbackName = 'Usuário';
  static const _fallbackAgency = 'Minha Agência';
  static const _fallbackRole = 'Administrador';

  @override
  Widget build(BuildContext context) {
    final et = EanTrackTheme.of(context);

    final displayName = userName.trim().isEmpty ? _fallbackName : userName.trim();
    final displayAgency =
        agencyName.trim().isEmpty ? _fallbackAgency : agencyName.trim();
    final displayRole = userRole.trim().isEmpty ? _fallbackRole : userRole.trim();
    final initial = displayName.substring(0, 1).toUpperCase();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.sm,
            0,
          ),
          child: Row(
            children: [
              Text(
                'MENU',
                style: AppTextStyles.labelSmall.copyWith(
                  color: et.secondaryText,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(Icons.close, size: 20, color: et.secondaryText),
                tooltip: 'Fechar menu',
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.sm,
            0,
            AppSpacing.sm,
            AppSpacing.sm,
          ),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: et.inputFill,
              borderRadius: AppRadius.mdAll,
              border: Border.all(color: et.surfaceBorder),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: et.ctaBackground,
                  backgroundImage:
                      avatarUrl != null ? NetworkImage(avatarUrl!) : null,
                  child: avatarUrl == null
                      ? Text(
                          initial,
                          style: AppTextStyles.titleSmall.copyWith(
                            color: et.ctaForeground,
                            fontWeight: FontWeight.w700,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: AppTextStyles.labelLarge.copyWith(
                          color: et.primaryText,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        displayAgency,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: et.secondaryText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        displayRole,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: et.secondaryText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Divider(height: 1, color: et.divider),
      ],
    );
  }
}
