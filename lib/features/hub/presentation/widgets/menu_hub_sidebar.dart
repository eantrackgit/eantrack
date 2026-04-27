import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../shared/shared.dart';
import '../../../onboarding/agency/controllers/agency_status_notifier.dart';

part 'sidebar_footer.dart';
part 'sidebar_header.dart';
part 'sidebar_item.dart';
part 'sidebar_section.dart';
part 'sidebar_sections.dart';

/// Sidebar lateral fixa para desktop/web que replica o MenuHub mobile.
class MenuHubSidebar extends ConsumerWidget {
  const MenuHubSidebar({
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

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: et.sidebarSurface,
        border: Border(right: BorderSide(color: et.inputBorder)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _MenuHubUserHeader(
                      userName: userName,
                      userRole: userRole,
                      agencyName: agencyName,
                      avatarUrl: userAvatarUrl,
                    ),
                    _MenuHubSections(
                      isBlocked: isBlocked,
                      agencyName: agencyName,
                      agencyHandle: agencyHandle,
                      agencyLogoUrl: agencyLogoUrl,
                      onEditAgency: onEditAgency,
                      activesCount: activesCount,
                      sentInvitesCount: sentInvitesCount,
                      pendingInvitesCount: pendingInvitesCount,
                      onManageInvites: onManageInvites,
                      planName: planName,
                      nextBillingText: nextBillingText,
                      onManagePlan: onManagePlan,
                    ),
                  ],
                ),
              ),
            ),
            _MenuHubFooter(onSignOut: onSignOut),
          ],
        ),
      ),
    );
  }
}
