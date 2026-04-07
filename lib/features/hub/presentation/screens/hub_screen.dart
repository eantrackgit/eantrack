import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../shared/layout/breakpoints.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_bottom_nav.dart';
import '../../../../shared/widgets/app_sidebar.dart';
import '../../../../shared/widgets/app_version_badge.dart';

/// Tela principal do app pós-login.
///
/// Desktop: AppSidebar fixa à esquerda + conteúdo à direita.
/// Mobile: conteúdo no topo + AppBottomNav na parte inferior.
class HubScreen extends StatefulWidget {
  const HubScreen({super.key});

  @override
  State<HubScreen> createState() => _HubScreenState();
}

class _HubScreenState extends State<HubScreen> {
  int _selectedIndex = 0;

  static const _modules = [
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

    if (isDesktop) {
      return Scaffold(
        backgroundColor: AppColors.primaryBackground,
        body: Row(
          children: [
            AppSidebar(
              userName: 'Usuário',
              userRole: 'Agência',
              selectedIndex: _selectedIndex,
              onItemTap: (i) => setState(() => _selectedIndex = i),
            ),
            Expanded(child: _Content(modules: _modules)),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: _Content(modules: _modules),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.modules});
  final List<_ModuleCard> modules;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _Header()),
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
  @override
  Widget build(BuildContext context) {
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
                  'Bom dia!',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
                Text(
                  'EANTrack',
                  style: AppTextStyles.headlineSmall.copyWith(
                    color: AppColors.primaryText,
                  ),
                ),
              ],
            ),
          ),
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.secondary,
            child: Text(
              'U',
              style: AppTextStyles.titleSmall.copyWith(
                color: AppColors.info,
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
    return Material(
      color: AppColors.secondaryBackground,
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
                  color: AppColors.secondary.withValues(alpha: 0.1),
                  borderRadius: AppRadius.smAll,
                ),
                child: Icon(
                  card.icon,
                  size: 20,
                  color: AppColors.secondary,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.label,
                    style: AppTextStyles.titleSmall.copyWith(
                      color: AppColors.primaryText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    card.description,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.secondaryText,
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
