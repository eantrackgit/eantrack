part of 'menu_hub_sidebar.dart';

class _MenuHubSections extends StatelessWidget {
  const _MenuHubSections({
    required this.isBlocked,
    required this.agencyName,
    required this.agencyHandle,
    this.agencyLogoUrl,
    this.onEditAgency,
    required this.activesCount,
    required this.sentInvitesCount,
    required this.pendingInvitesCount,
    this.onManageInvites,
    required this.planName,
    required this.nextBillingText,
    this.onManagePlan,
    this.collapsible = false,
  });

  final bool isBlocked;
  final String agencyName;
  final String agencyHandle;
  final String? agencyLogoUrl;
  final VoidCallback? onEditAgency;
  final int activesCount;
  final int sentInvitesCount;
  final int pendingInvitesCount;
  final VoidCallback? onManageInvites;
  final String planName;
  final String nextBillingText;
  final VoidCallback? onManagePlan;

  /// Mobile: cada grupo vira accordion (ver [_MenuHubSection]). Desktop mantém
  /// os grupos sempre expandidos.
  final bool collapsible;

  @override
  Widget build(BuildContext context) {
    final enabled = !isBlocked;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MenuHubSection(
          icon: Icons.badge_rounded,
          title: 'Identidade',
          wrapInCard: false,
          collapsible: collapsible,
          initiallyExpanded: true,
          children: [
            _MenuHubIdentityCard(
              agencyName: agencyName,
              agencyHandle: agencyHandle,
              logoUrl: agencyLogoUrl,
              onEditAgency: isBlocked ? null : onEditAgency,
            ),
          ],
        ),
        _MenuHubStructureSection(enabled: enabled, collapsible: collapsible),
        _MenuHubOperationalSection(
          enabled: enabled,
          collapsible: collapsible,
          activesCount: activesCount,
          sentInvitesCount: sentInvitesCount,
          pendingInvitesCount: pendingInvitesCount,
          onManageInvites: onManageInvites,
        ),
        _MenuHubPlanSection(
          enabled: enabled,
          collapsible: collapsible,
          planName: planName,
          nextBillingText: nextBillingText,
          onManagePlan: onManagePlan,
        ),
        _MenuHubAccountSection(enabled: enabled, collapsible: collapsible),
      ],
    );
  }
}

class _MenuHubStructureSection extends StatelessWidget {
  const _MenuHubStructureSection({
    required this.enabled,
    this.collapsible = false,
  });

  final bool enabled;
  final bool collapsible;

  @override
  Widget build(BuildContext context) {
    return _MenuHubSection(
      icon: Icons.account_tree_outlined,
      title: 'Estrutura',
      collapsible: collapsible,
      initiallyExpanded: true,
      children: [
        _MenuHubSectionItem(
          icon: Icons.location_on_outlined,
          label: 'Regiões',
          enabled: enabled,
          onTap: enabled ? () => context.go(AppRoutes.regions) : null,
        ),
        _MenuHubSectionItem(icon: Icons.hub_outlined, label: 'Redes', enabled: enabled),
        _MenuHubSectionItem(icon: Icons.store_outlined, label: 'Lojas / PDVs', enabled: enabled),
        _MenuHubSectionItem(
          icon: Icons.category_outlined,
          label: 'Categorias / Subcategorias',
          enabled: enabled,
        ),
        _MenuHubSectionItem(icon: Icons.factory_outlined, label: 'Indústrias / Marcas', enabled: enabled),
        _MenuHubSectionItem(icon: Icons.groups_outlined, label: 'Equipes', enabled: enabled),
        _MenuHubSectionItem(icon: Icons.people_outline_rounded, label: 'Colaboradores', enabled: enabled),
        _MenuHubSectionItem(icon: Icons.assignment_outlined, label: 'Tarefas / Pesquisas', enabled: enabled),
      ],
    );
  }
}

class _MenuHubOperationalSection extends StatelessWidget {
  const _MenuHubOperationalSection({
    required this.enabled,
    required this.activesCount,
    required this.sentInvitesCount,
    required this.pendingInvitesCount,
    this.onManageInvites,
    this.collapsible = false,
  });

  final bool enabled;
  final int activesCount;
  final int sentInvitesCount;
  final int pendingInvitesCount;
  final VoidCallback? onManageInvites;
  final bool collapsible;

  @override
  Widget build(BuildContext context) {
    return _MenuHubSection(
      icon: Icons.groups_2_outlined,
      title: 'Operacional',
      collapsible: collapsible,
      initiallyExpanded: false,
      children: [
        _MenuHubSectionItem(icon: Icons.inventory_2_outlined, label: 'Ativos', count: activesCount, enabled: enabled),
        _MenuHubSectionItem(icon: Icons.mail_outline_rounded, label: 'Convites enviados', count: sentInvitesCount, enabled: enabled),
        _MenuHubSectionItem(icon: Icons.mark_email_unread_outlined, label: 'Convites pendentes', count: pendingInvitesCount, enabled: enabled),
        if (enabled)
          _MenuHubActionButton(
            label: 'Gerenciar convites',
            onPressed: onManageInvites,
          ),
      ],
    );
  }
}

class _MenuHubPlanSection extends StatelessWidget {
  const _MenuHubPlanSection({
    required this.enabled,
    required this.planName,
    required this.nextBillingText,
    this.onManagePlan,
    this.collapsible = false,
  });

  final bool enabled;
  final String planName;
  final String nextBillingText;
  final VoidCallback? onManagePlan;
  final bool collapsible;

  @override
  Widget build(BuildContext context) {
    return _MenuHubSection(
      icon: Icons.credit_card_outlined,
      title: 'Planos & Pagamentos',
      collapsible: collapsible,
      initiallyExpanded: false,
      children: [
        _MenuHubSectionItem(
          icon: Icons.workspace_premium_outlined,
          label: planName,
          enabled: enabled,
        ),
        if (nextBillingText.isNotEmpty && enabled)
          _MenuHubBillingRow(text: nextBillingText),
        if (enabled)
          _MenuHubActionButton(
            label: 'Gerenciar plano',
            onPressed: onManagePlan,
          ),
      ],
    );
  }
}

class _MenuHubAccountSection extends StatelessWidget {
  const _MenuHubAccountSection({
    required this.enabled,
    this.collapsible = false,
  });

  final bool enabled;
  final bool collapsible;

  @override
  Widget build(BuildContext context) {
    return _MenuHubSection(
      icon: Icons.manage_accounts_outlined,
      title: 'Minha Conta',
      collapsible: collapsible,
      initiallyExpanded: false,
      children: [
        _MenuHubSectionItem(
          icon: Icons.settings_outlined,
          label: 'Configura\u00e7\u00f5es',
          enabled: enabled,
          onTap: enabled ? () => showUserSettingsDialog(context) : null,
        ),
        _MenuHubSectionItem(
          icon: Icons.delete_outline_rounded,
          label: 'Excluir conta',
          enabled: enabled,
          isDestructive: true,
        ),
      ],
    );
  }
}
