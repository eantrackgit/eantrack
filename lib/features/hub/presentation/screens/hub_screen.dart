import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../shared/shared.dart';
import '../../../auth/domain/auth_state.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../onboarding/agency/controllers/agency_status_notifier.dart';
import '../widgets/menu_hub_sidebar.dart';

/// Tela principal do app pós-login.
///
/// Desktop: MenuHubSidebar fixa à esquerda + conteúdo à direita.
/// Mobile: conteúdo no topo + AppBottomNav na parte inferior.
class HubScreen extends ConsumerStatefulWidget {
  const HubScreen({super.key});

  @override
  ConsumerState<HubScreen> createState() => _HubScreenState();
}

class _HubScreenState extends ConsumerState<HubScreen> {
  int _selectedIndex = 0;

  static const _modules = [
    _ModuleCard(
      icon: Icons.event_available_outlined,
      label: 'Validade',
      description: 'Lançamentos e vencimentos',
      route: AppRoutes.validity,
    ),
    _ModuleCard(
      icon: Icons.map_outlined,
      label: 'Regiões',
      description: 'Gerencie territórios e cidades',
      route: AppRoutes.regions,
    ),
    _ModuleCard(
      icon: Icons.store_outlined,
      label: 'PDVs',
      description: 'Pontos de venda cadastrados',
      route: AppRoutes.pdvs,
    ),
    _ModuleCard(
      icon: Icons.hub_outlined,
      label: 'Redes',
      description: 'Redes e bandeiras de mercado',
      route: AppRoutes.networks,
    ),
    _ModuleCard(
      icon: Icons.category_outlined,
      label: 'Categorias',
      description: 'Produtos por categoria',
      route: AppRoutes.categories,
    ),
    _ModuleCard(
      icon: Icons.factory_outlined,
      label: 'Indústrias',
      description: 'Fabricantes e portfolios',
      route: AppRoutes.industries,
    ),
    _ModuleCard(
      icon: Icons.group_outlined,
      label: 'Equipe',
      description: 'Promotores e agentes',
      route: null, // Fase futura
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDesktop = Breakpoints.isDesktop(context);
    final authState = ref.watch(authNotifierProvider);
    final agencyProvider = agencyStatusProvider(null);
    final agencyState = ref.watch(agencyProvider);
    final agencyData = agencyState.data;
    final userName = _resolveUserName(authState);
    final userRole = _resolveUserRole(authState);
    final agencyName = agencyData?.agencyLegalName ?? '';
    final agencyStatus = agencyData?.statusAgency ?? AgencyDocumentStatus.pending;

    if (agencyState.status == AgencyStatusLoading.idle) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        ref.read(agencyProvider.notifier).load();
      });
    }

    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            MenuHubSidebar(
              userName: userName,
              userRole: userRole,
              agencyName: agencyName,
              agencyHandle: _agencyHandleFromName(agencyName),
              agencyStatus: agencyStatus,
              planName: '',
              onSignOut: () async {
                await ref.read(authNotifierProvider.notifier).signOut();
                if (!context.mounted) return;
                context.go(AppRoutes.login);
              },
            ),
            Expanded(
              child: _Content(
                modules: _modules,
                userName: userName,
                agencyName: agencyName,
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: _Content(
        modules: _modules,
        userName: userName,
        agencyName: agencyName,
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({
    required this.modules,
    required this.userName,
    required this.agencyName,
  });

  final List<_ModuleCard> modules;
  final String userName;
  final String agencyName;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _Header(userName: userName, agencyName: agencyName),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.xl,
            ),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 280,
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.md,
                childAspectRatio: 1.5,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, i) => _ModuleCardWidget(card: modules[i]),
                childCount: modules.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.xl,
              ),
              child: AppVersionBadge(
                alignment: Alignment.centerRight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.userName, required this.agencyName});

  final String userName;
  final String agencyName;

  @override
  Widget build(BuildContext context) {
    final et = EanTrackTheme.of(context);
    final initial = _initialFromName(userName);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  agencyName,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: et.secondaryText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  userName,
                  style: AppTextStyles.headlineSmall.copyWith(
                    color: et.primaryText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          CircleAvatar(
            radius: 20,
            backgroundColor: et.ctaBackground,
            child: Text(
              initial,
              style: AppTextStyles.titleSmall.copyWith(
                color: et.ctaForeground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModuleCardWidget extends StatelessWidget {
  const _ModuleCardWidget({required this.card});
  final _ModuleCard card;

  @override
  Widget build(BuildContext context) {
    final et = EanTrackTheme.of(context);
    return Material(
      color: et.cardSurface,
      borderRadius: AppRadius.mdAll,
      child: InkWell(
        borderRadius: AppRadius.mdAll,
        onTap: card.route != null ? () => context.push(card.route!) : null,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: et.ctaBackground.withValues(alpha: 0.1),
                  borderRadius: AppRadius.smAll,
                ),
                child: Icon(
                  card.icon,
                  size: 20,
                  color: et.ctaBackground,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.label,
                    style: AppTextStyles.titleSmall.copyWith(
                      color: et.primaryText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    card.description,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: et.secondaryText,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModuleCard {
  const _ModuleCard({
    required this.icon,
    required this.label,
    required this.description,
    required this.route,
  });

  final IconData icon;
  final String label;
  final String description;
  final String? route;
}

String _resolveUserName(AuthState authState) {
  if (authState is! AuthAuthenticated) return '';

  final flowName = authState.flowState?.nome?.trim();
  if (flowName != null && flowName.isNotEmpty) return flowName;

  final metadataName = _firstMetadataValue(authState.user.userMetadata, const [
    'nome',
    'name',
    'full_name',
    'display_name',
  ]);
  if (metadataName != null) return metadataName;

  final email = authState.user.email?.trim();
  if (email == null || email.isEmpty) return '';

  final separatorIndex = email.indexOf('@');
  if (separatorIndex <= 0) return email;
  return email.substring(0, separatorIndex);
}

String _resolveUserRole(AuthState authState) {
  if (authState is! AuthAuthenticated) return '';

  return _firstMetadataValue(authState.user.userMetadata, const [
        'role',
        'user_role',
        'cargo',
      ]) ??
      '';
}

String? _firstMetadataValue(
  Map<String, dynamic>? metadata,
  List<String> keys,
) {
  if (metadata == null) return null;

  for (final key in keys) {
    final value = metadata[key]?.toString().trim();
    if (value != null && value.isNotEmpty) return value;
  }

  return null;
}

String _initialFromName(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return '?';
  return trimmed.substring(0, 1).toUpperCase();
}

String _agencyHandleFromName(String agencyName) {
  return agencyName
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '');
}
