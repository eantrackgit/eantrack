import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../shared/shared.dart';
import '../../../onboarding/agency/controllers/agency_status_notifier.dart';

/// Sidebar lateral fixa para desktop/web que replica o MenuHub mobile.
///
/// Uso em HubScreen (desktop layout):
///   MenuHubSidebar(
///     userName: 'Marcio José',
///     userRole: 'Administrador',
///     agencyName: 'ABC Promotores',
///     agencyHandle: 'abcpromotores',
///     agencyStatus: AgencyDocumentStatus.approved,
///     onSignOut: () => ...,
///   )
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
                    _MenuHubSection(
                      icon: Icons.badge_rounded,
                      title: 'Identidade',
                      wrapInCard: false,
                      children: [
                        _MenuHubIdentityCard(
                          agencyName: agencyName,
                          agencyHandle: agencyHandle,
                          logoUrl: agencyLogoUrl,
                          onEditAgency: isBlocked ? null : onEditAgency,
                        ),
                      ],
                    ),
                    _MenuHubSection(
                      icon: Icons.account_tree_outlined,
                      title: 'Estrutura',
                      children: [
                        _MenuHubSectionItem(
                          icon: Icons.location_on_outlined,
                          label: 'Regiões',
                          enabled: !isBlocked,
                          onTap: isBlocked
                              ? null
                              : () => context.go(AppRoutes.regions),
                        ),
                        _MenuHubSectionItem(
                          icon: Icons.hub_outlined,
                          label: 'Redes',
                          enabled: !isBlocked,
                          onTap: null,
                        ),
                        _MenuHubSectionItem(
                          icon: Icons.store_outlined,
                          label: 'Lojas / PDVs',
                          enabled: !isBlocked,
                          onTap: null,
                        ),
                        _MenuHubSectionItem(
                          icon: Icons.category_outlined,
                          label: 'Categorias / Subcategorias',
                          enabled: !isBlocked,
                          onTap: null,
                        ),
                        _MenuHubSectionItem(
                          icon: Icons.factory_outlined,
                          label: 'Indústrias / Marcas',
                          enabled: !isBlocked,
                          onTap: null,
                        ),
                        _MenuHubSectionItem(
                          icon: Icons.groups_outlined,
                          label: 'Equipes',
                          enabled: !isBlocked,
                          onTap: null,
                        ),
                        _MenuHubSectionItem(
                          icon: Icons.people_outline_rounded,
                          label: 'Colaboradores',
                          enabled: !isBlocked,
                          onTap: null,
                        ),
                        _MenuHubSectionItem(
                          icon: Icons.assignment_outlined,
                          label: 'Tarefas / Pesquisas',
                          enabled: !isBlocked,
                          onTap: null,
                        ),
                      ],
                    ),
                    _MenuHubSection(
                      icon: Icons.groups_2_outlined,
                      title: 'Operacional',
                      children: [
                        _MenuHubSectionItem(
                          icon: Icons.inventory_2_outlined,
                          label: 'Ativos',
                          count: activesCount,
                          enabled: !isBlocked,
                          onTap: null,
                        ),
                        _MenuHubSectionItem(
                          icon: Icons.mail_outline_rounded,
                          label: 'Convites enviados',
                          count: sentInvitesCount,
                          enabled: !isBlocked,
                          onTap: null,
                        ),
                        _MenuHubSectionItem(
                          icon: Icons.mark_email_unread_outlined,
                          label: 'Convites pendentes',
                          count: pendingInvitesCount,
                          enabled: !isBlocked,
                          onTap: null,
                        ),
                        if (!isBlocked)
                          _MenuHubActionButton(
                            label: 'Gerenciar convites',
                            onPressed: onManageInvites,
                          ),
                      ],
                    ),
                    _MenuHubSection(
                      icon: Icons.credit_card_outlined,
                      title: 'Planos & Pagamentos',
                      children: [
                        _MenuHubSectionItem(
                          icon: Icons.workspace_premium_outlined,
                          label: planName,
                          enabled: !isBlocked,
                          onTap: null,
                        ),
                        if (nextBillingText.isNotEmpty && !isBlocked)
                          _MenuHubBillingRow(text: nextBillingText),
                        if (!isBlocked)
                          _MenuHubActionButton(
                            label: 'Gerenciar plano',
                            onPressed: onManagePlan,
                          ),
                      ],
                    ),
                    _MenuHubSection(
                      icon: Icons.manage_accounts_outlined,
                      title: 'Minha Conta',
                      children: [
                        _MenuHubSectionItem(
                          icon: Icons.delete_outline_rounded,
                          label: 'Excluir conta',
                          enabled: !isBlocked,
                          isDestructive: true,
                          onTap: null,
                        ),
                      ],
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

// ---------------------------------------------------------------------------
// User Header
// ---------------------------------------------------------------------------

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
                backgroundImage:
                    avatarUrl != null ? NetworkImage(avatarUrl!) : null,
                child: avatarUrl == null
                    ? Icon(
                        Icons.person_rounded,
                        size: 22,
                        color: et.ctaBackground,
                      )
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
                      style: AppTextStyles.labelSmall.copyWith(
                        color: et.secondaryText,
                      ),
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

// ---------------------------------------------------------------------------
// Identity Card
// ---------------------------------------------------------------------------

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
                backgroundImage:
                    logoUrl != null ? NetworkImage(logoUrl!) : null,
                child: logoUrl == null
                    ? Icon(
                        Icons.support_agent_rounded,
                        size: 26,
                        color: et.secondaryText,
                      )
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
                      style: AppTextStyles.labelSmall.copyWith(
                        color: et.secondaryText,
                      ),
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
                style: AppTextStyles.labelSmall.copyWith(
                  color: et.secondaryText,
                ),
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

// ---------------------------------------------------------------------------
// Section
// ---------------------------------------------------------------------------

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

  /// Quando true, os filhos ficam dentro de um card com fundo e borda.
  /// Usar false para seções com cards próprios (ex: Identidade).
  final bool wrapInCard;

  @override
  Widget build(BuildContext context) {
    final et = EanTrackTheme.of(context);

    final Widget childrenWidget = wrapInCard
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

// ---------------------------------------------------------------------------
// Section Item
// ---------------------------------------------------------------------------

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

    final Color iconColor = isDestructive
        ? AppColors.error
        : et.primaryText.withValues(alpha: 0.8);
    final Color textColor =
        isDestructive ? AppColors.error : et.primaryText;

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
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: row,
      ),
    );

    if (!enabled) {
      return Opacity(opacity: 0.45, child: interactive);
    }

    return interactive;
  }
}

// ---------------------------------------------------------------------------
// Action Button (Gerenciar convites, Gerenciar plano)
// ---------------------------------------------------------------------------

class _MenuHubActionButton extends StatelessWidget {
  const _MenuHubActionButton({
    required this.label,
    this.onPressed,
  });

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

// ---------------------------------------------------------------------------
// Billing row (Próxima fatura em...)
// ---------------------------------------------------------------------------

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
          const Icon(Icons.receipt_outlined, size: 13, color: AppColors.success),
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

// ---------------------------------------------------------------------------
// Footer (Sair da conta)
// ---------------------------------------------------------------------------

class _MenuHubFooter extends StatelessWidget {
  const _MenuHubFooter({required this.onSignOut});

  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final et = EanTrackTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Divider(height: 1, color: et.divider),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: SizedBox(
            height: 46,
            child: ElevatedButton(
              onPressed: onSignOut,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: et.ctaForeground,
                elevation: 0,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: AppRadius.smAll),
              ),
              child: Text(
                'Sair da conta',
                style: AppTextStyles.labelMedium.copyWith(
                  color: et.ctaForeground,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(bottom: AppSpacing.md),
          child: AppVersionBadge(),
        ),
      ],
    );
  }
}
