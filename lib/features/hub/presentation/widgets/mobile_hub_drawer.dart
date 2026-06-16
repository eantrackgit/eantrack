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
        ),
      ),
    );
  }
}
