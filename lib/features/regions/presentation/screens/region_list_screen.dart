import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../shared/shared.dart';
import '../../../auth/domain/auth_state.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../hub/presentation/widgets/menu_hub_sidebar.dart';
import '../../../onboarding/agency/controllers/agency_status_notifier.dart';
import '../../domain/region_model.dart';
import '../../domain/region_state.dart';
import '../providers/region_provider.dart';

class RegionListScreen extends ConsumerStatefulWidget {
  const RegionListScreen({super.key});

  @override
  ConsumerState<RegionListScreen> createState() => _RegionListScreenState();
}

class _RegionListScreenState extends ConsumerState<RegionListScreen> {
  String _search = '';
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final et = EanTrackTheme.of(context);
    final isDesktop = Breakpoints.isDesktop(context);
    final regionState = ref.watch(regionNotifierProvider);
    final authState = ref.watch(authNotifierProvider);
    final agencyProvider = agencyStatusProvider(null);
    final agencyState = ref.watch(agencyProvider);
    final agencyData = agencyState.data;

    if (agencyState.status == AgencyStatusLoading.idle) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        ref.read(agencyProvider.notifier).load();
      });
    }

    final userName = _resolveUserName(authState);
    final userRole = _resolveUserRole(authState);
    final agencyName = agencyData?.agencyLegalName ?? '';
    final agencyStatus =
        agencyData?.statusAgency ?? AgencyDocumentStatus.pending;

    final content = isDesktop
        ? _DesktopRegionContent(
            state: regionState,
            search: _search,
            tabIndex: _tabIndex,
            onSearchChanged: (v) => setState(() => _search = v),
            onTabChanged: (i) => setState(() => _tabIndex = i),
            onAdd: () => _showCreateDialog(context),
            onRetry: () => ref.read(regionNotifierProvider.notifier).load(),
            onToggleActive: _toggleRegionActive,
          )
        : _MobileRegionContent(
            state: regionState,
            search: _search,
            tabIndex: _tabIndex,
            onSearchChanged: (v) => setState(() => _search = v),
            onTabChanged: (i) => setState(() => _tabIndex = i),
            onAdd: () => _showCreateDialog(context),
            onRetry: () => ref.read(regionNotifierProvider.notifier).load(),
            onToggleActive: _toggleRegionActive,
          );

    if (isDesktop) {
      return Scaffold(
        backgroundColor: et.sidebarSurface,
        body: Row(
          children: [
            MenuHubSidebar(
              userName: userName,
              userRole: userRole,
              agencyName: agencyName,
              agencyHandle: _agencyHandleFromName(agencyName),
              agencyStatus: agencyStatus,
              onSignOut: () async {
                await ref.read(authNotifierProvider.notifier).signOut();
                if (!context.mounted) return;
                context.go(AppRoutes.login);
              },
            ),
            Expanded(child: content),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: et.scaffoldOuter,
      body: content,
    );
  }

  void _toggleRegionActive(String id, bool active) {
    ref.read(regionNotifierProvider.notifier).toggleActive(id, isActive: active);
  }

  Future<void> _showCreateDialog(BuildContext context) async {
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierLabel: '',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (ctx, _, __) => _CreateRegionDialog(
        onConfirm: (name) =>
            ref.read(regionNotifierProvider.notifier).createRegion(name),
        checkName: (name) =>
            ref.read(regionNotifierProvider.notifier).isNameAvailable(name),
      ),
      transitionBuilder: (ctx, anim, __, child) {
        final fade = CurvedAnimation(parent: anim, curve: Curves.easeOut);
        return Stack(
          children: [
            Positioned.fill(
              child: FadeTransition(
                opacity: fade,
                child: const ColoredBox(color: Color(0x80000000)),
              ),
            ),
            Positioned.fill(
              child: FadeTransition(
                opacity: fade,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                    CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
                  ),
                  child: child,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MobileRegionContent extends StatelessWidget {
  const _MobileRegionContent({
    required this.state,
    required this.search,
    required this.tabIndex,
    required this.onSearchChanged,
    required this.onTabChanged,
    required this.onAdd,
    required this.onRetry,
    required this.onToggleActive,
  });

  final RegionState state;
  final String search;
  final int tabIndex;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<int> onTabChanged;
  final VoidCallback onAdd;
  final VoidCallback onRetry;
  final void Function(String id, bool active) onToggleActive;

  @override
  Widget build(BuildContext context) {
    final et = EanTrackTheme.of(context);
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.lg),
            ),
            child: ColoredBox(
              color: et.cardSurface,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _MobileHeader(onAdd: onAdd),
                  _FilterChips(
                    selectedIndex: tabIndex,
                    onChanged: onTabChanged,
                    compact: true,
                  ),
                  _RegionSearchField(
                    onChanged: onSearchChanged,
                    hintText: 'Buscar região',
                  ),
                  Expanded(
                    child: _RegionBody(
                      state: state,
                      search: search,
                      tabIndex: tabIndex,
                      onRetry: onRetry,
                      onAdd: onAdd,
                      onToggleActive: onToggleActive,
                      isDesktop: false,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DesktopRegionContent extends StatelessWidget {
  const _DesktopRegionContent({
    required this.state,
    required this.search,
    required this.tabIndex,
    required this.onSearchChanged,
    required this.onTabChanged,
    required this.onAdd,
    required this.onRetry,
    required this.onToggleActive,
  });

  final RegionState state;
  final String search;
  final int tabIndex;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<int> onTabChanged;
  final VoidCallback onAdd;
  final VoidCallback onRetry;
  final void Function(String id, bool active) onToggleActive;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 20, 48, 24),
        child: Align(
          alignment: const Alignment(-0.10, -1),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1280),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _DesktopHeader(onAdd: onAdd),
                const SizedBox(height: AppSpacing.lg),
                _DesktopControls(
                  selectedIndex: tabIndex,
                  onTabChanged: onTabChanged,
                  onSearchChanged: onSearchChanged,
                ),
                const SizedBox(height: AppSpacing.md),
                Expanded(
                  child: _RegionBody(
                    state: state,
                    search: search,
                    tabIndex: tabIndex,
                    onRetry: onRetry,
                    onAdd: onAdd,
                    onToggleActive: onToggleActive,
                    isDesktop: true,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MobileHeader extends StatelessWidget {
  const _MobileHeader({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final et = EanTrackTheme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.xs,
      ),
      child: SizedBox(
        height: 48,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                color: et.primaryText,
                onPressed: () => Navigator.of(context).maybePop(),
                tooltip: 'Voltar',
              ),
            ),
            Text(
              'Regiões',
              style: AppTextStyles.titleMedium.copyWith(
                color: et.primaryText,
                fontWeight: FontWeight.w700,
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: const Icon(Icons.add_rounded),
                color: et.ctaBackground,
                onPressed: onAdd,
                tooltip: 'Nova região',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DesktopHeader extends StatelessWidget {
  const _DesktopHeader({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final et = EanTrackTheme.of(context);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Regiões',
                style: AppTextStyles.headlineSmall.copyWith(
                  color: et.primaryText,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Gerencie territórios e cidades da agência.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: et.secondaryText,
                ),
              ),
            ],
          ),
        ),
        AppButton.primary(
          'Nova região',
          onPressed: onAdd,
          width: 170,
          leadingIcon: const Icon(Icons.add_rounded, size: 18),
        ),
      ],
    );
  }
}

class _DesktopControls extends StatelessWidget {
  const _DesktopControls({
    required this.selectedIndex,
    required this.onTabChanged,
    required this.onSearchChanged,
  });

  final int selectedIndex;
  final ValueChanged<int> onTabChanged;
  final ValueChanged<String> onSearchChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _FilterChips(
          selectedIndex: selectedIndex,
          onChanged: onTabChanged,
          compact: false,
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _RegionSearchField(
            onChanged: onSearchChanged,
            hintText: 'Buscar por região',
          ),
        ),
      ],
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({
    required this.selectedIndex,
    required this.onChanged,
    required this.compact,
  });

  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final bool compact;

  static const _labels = ['Todas', 'Ativas', 'Inativas'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: compact
          ? const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs,
              AppSpacing.md, AppSpacing.sm)
          : EdgeInsets.zero,
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: List.generate(
          _labels.length,
          (i) => _FilterChipButton(
            label: _labels[i],
            selected: selectedIndex == i,
            onTap: () => onChanged(i),
          ),
        ),
      ),
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  const _FilterChipButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final et = EanTrackTheme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.full),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: selected ? et.ctaBackground : et.surface,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
            color: selected ? et.ctaBackground : et.surfaceBorder,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: selected ? et.ctaForeground : et.secondaryText,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _RegionSearchField extends StatelessWidget {
  const _RegionSearchField({
    required this.onChanged,
    required this.hintText,
  });

  final ValueChanged<String> onChanged;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    final et = EanTrackTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: TextField(
        onChanged: onChanged,
        style: AppTextStyles.bodyMedium.copyWith(color: et.primaryText),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: AppTextStyles.bodyMedium.copyWith(
            color: et.secondaryText,
          ),
          prefixIcon: Icon(Icons.search_rounded, color: et.secondaryText),
          filled: true,
          fillColor: et.inputFill,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          border: OutlineInputBorder(
            borderRadius: AppRadius.smAll,
            borderSide: BorderSide(color: et.inputBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: AppRadius.smAll,
            borderSide: BorderSide(color: et.inputBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: AppRadius.smAll,
            borderSide: BorderSide(color: et.inputBorderFocused, width: 1.5),
          ),
        ),
      ),
    );
  }
}

class _RegionBody extends StatelessWidget {
  const _RegionBody({
    required this.state,
    required this.search,
    required this.tabIndex,
    required this.onRetry,
    required this.onAdd,
    required this.onToggleActive,
    required this.isDesktop,
  });

  final RegionState state;
  final String search;
  final int tabIndex;
  final VoidCallback onRetry;
  final VoidCallback onAdd;
  final void Function(String id, bool active) onToggleActive;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    final regions = state is RegionLoaded
        ? _filter((state as RegionLoaded).regions)
        : <RegionModel>[];

    if (state is RegionInitial || state is RegionLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is RegionError) {
      return _RegionErrorState(
        message: (state as RegionError).message,
        onRetry: onRetry,
      );
    }

    if (state is RegionLoaded && regions.isEmpty) {
      return _RegionEmptyState(isDesktop: isDesktop, onAdd: onAdd);
    }

    return isDesktop
        ? _DesktopRegionTable(
            regions: regions,
            onToggleActive: onToggleActive,
          )
        : _MobileRegionList(
            regions: regions,
            onToggleActive: onToggleActive,
          );
  }

  List<RegionModel> _filter(List<RegionModel> regions) {
    var result = regions;

    if (tabIndex == 1) result = result.where((r) => r.isActive).toList();
    if (tabIndex == 2) result = result.where((r) => !r.isActive).toList();

    final q = search.trim().toLowerCase();
    if (q.isNotEmpty) {
      result = result.where((r) => r.name.toLowerCase().contains(q)).toList();
    }

    return result;
  }
}

class _MobileRegionList extends StatelessWidget {
  const _MobileRegionList({
    required this.regions,
    required this.onToggleActive,
  });

  final List<RegionModel> regions;
  final void Function(String id, bool active) onToggleActive;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md + MediaQuery.paddingOf(context).bottom,
      ),
      itemCount: regions.length,
      separatorBuilder: (_, __) => Divider(
        height: AppSpacing.md,
        color: EanTrackTheme.of(context).divider.withValues(alpha: 0.65),
      ),
      itemBuilder: (_, i) => _MobileRegionRow(
        region: regions[i],
        onToggleActive: onToggleActive,
      ),
    );
  }
}

class _MobileRegionRow extends StatelessWidget {
  const _MobileRegionRow({
    required this.region,
    required this.onToggleActive,
  });

  final RegionModel region;
  final void Function(String id, bool active) onToggleActive;

  @override
  Widget build(BuildContext context) {
    final et = EanTrackTheme.of(context);
    return Material(
      color: et.surface.withValues(alpha: 0.72),
      borderRadius: AppRadius.smAll,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          region.name,
                          style: AppTextStyles.titleSmall.copyWith(
                            color: et.primaryText,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _StatusBadge(isActive: region.isActive),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.md,
                    runSpacing: AppSpacing.xs,
                    children: [
                      _MetaText(
                        icon: Icons.location_city_outlined,
                        text: _citiesText(region.cityCount),
                      ),
                      const _MetaText(
                        icon: Icons.store_outlined,
                        text: '0 PDVs',
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  const _MetaText(
                    icon: Icons.schedule_rounded,
                    text: 'Atualização não informada',
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            _RegionActionsMenu(
              region: region,
              onToggleActive: onToggleActive,
            ),
          ],
        ),
      ),
    );
  }
}

class _DesktopRegionTable extends StatelessWidget {
  const _DesktopRegionTable({
    required this.regions,
    required this.onToggleActive,
  });

  final List<RegionModel> regions;
  final void Function(String id, bool active) onToggleActive;

  @override
  Widget build(BuildContext context) {
    final et = EanTrackTheme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: et.cardSurface,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: et.surfaceBorder),
      ),
      child: Column(
        children: [
          const _DesktopTableHeader(),
          Divider(height: 1, color: et.divider),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: regions.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                color: et.divider.withValues(alpha: 0.75),
              ),
              itemBuilder: (_, i) => _DesktopRegionRow(
                region: regions[i],
                onToggleActive: onToggleActive,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DesktopTableHeader extends StatelessWidget {
  const _DesktopTableHeader();

  @override
  Widget build(BuildContext context) {
    final et = EanTrackTheme.of(context);
    final style = AppTextStyles.labelSmall.copyWith(
      color: et.secondaryText,
      fontWeight: FontWeight.w700,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
      ),
      child: Row(
        children: [
          Expanded(flex: 4, child: Text('Região', style: style)),
          Expanded(flex: 2, child: Text('Status', style: style)),
          Expanded(flex: 2, child: Text('Cidades', style: style)),
          Expanded(flex: 2, child: Text('PDVs', style: style)),
          Expanded(flex: 3, child: Text('Última atualização', style: style)),
          SizedBox(
            width: 72,
            child: Text('Ações', style: style, textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }
}

class _DesktopRegionRow extends StatelessWidget {
  const _DesktopRegionRow({
    required this.region,
    required this.onToggleActive,
  });

  final RegionModel region;
  final void Function(String id, bool active) onToggleActive;

  @override
  Widget build(BuildContext context) {
    final et = EanTrackTheme.of(context);
    final bodyStyle = AppTextStyles.bodyMedium.copyWith(
      color: et.primaryText,
    );
    final mutedStyle = AppTextStyles.bodySmall.copyWith(
      color: et.secondaryText,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: et.ctaBackground.withValues(alpha: 0.10),
                    borderRadius: AppRadius.smAll,
                  ),
                  child: Icon(
                    Icons.map_outlined,
                    size: 18,
                    color: et.ctaBackground,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    region.name,
                    style: bodyStyle.copyWith(fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(flex: 2, child: _StatusBadge(isActive: region.isActive)),
          Expanded(
            flex: 2,
            child: Text(_citiesText(region.cityCount), style: bodyStyle),
          ),
          Expanded(flex: 2, child: Text('0 PDVs', style: bodyStyle)),
          Expanded(
            flex: 3,
            child: Text('Não informada', style: mutedStyle),
          ),
          SizedBox(
            width: 72,
            child: Align(
              alignment: Alignment.center,
              child: _RegionActionsMenu(
                region: region,
                onToggleActive: onToggleActive,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final et = EanTrackTheme.of(context);
    final color = isActive ? AppColors.success : et.secondaryText;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(color: color.withValues(alpha: 0.24)),
        ),
        child: Text(
          isActive ? 'Ativa' : 'Inativa',
          style: AppTextStyles.labelSmall.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _MetaText extends StatelessWidget {
  const _MetaText({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final et = EanTrackTheme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: et.secondaryText),
        const SizedBox(width: AppSpacing.xs),
        Text(
          text,
          style: AppTextStyles.bodySmall.copyWith(
            color: et.secondaryText,
          ),
        ),
      ],
    );
  }
}

enum _RegionAction { toggleActive }

class _RegionActionsMenu extends StatelessWidget {
  const _RegionActionsMenu({
    required this.region,
    required this.onToggleActive,
  });

  final RegionModel region;
  final void Function(String id, bool active) onToggleActive;

  @override
  Widget build(BuildContext context) {
    final et = EanTrackTheme.of(context);
    return PopupMenuButton<_RegionAction>(
      color: et.cardSurface,
      icon: Icon(Icons.more_vert_rounded, color: et.secondaryText),
      tooltip: 'Ações',
      onSelected: (_) => onToggleActive(region.id, !region.isActive),
      itemBuilder: (_) => [
        PopupMenuItem<_RegionAction>(
          value: _RegionAction.toggleActive,
          child: Row(
            children: [
              Icon(
                region.isActive
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 18,
                color: et.primaryText,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                region.isActive ? 'Desativar' : 'Ativar',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: et.primaryText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RegionEmptyState extends StatelessWidget {
  const _RegionEmptyState({
    required this.isDesktop,
    required this.onAdd,
  });

  final bool isDesktop;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final et = EanTrackTheme.of(context);
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.map_outlined, size: 42, color: et.secondaryText),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Nenhuma região encontrada',
          style: AppTextStyles.titleSmall.copyWith(
            color: et.primaryText,
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Crie uma região para organizar territórios e cidades.',
          style: AppTextStyles.bodySmall.copyWith(color: et.secondaryText),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.lg),
        AppButton.primary(
          'Nova região',
          onPressed: onAdd,
          width: 180,
          leadingIcon: const Icon(Icons.add_rounded, size: 18),
        ),
      ],
    );

    if (!isDesktop) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: content,
        ),
      );
    }

    return Center(
      child: Container(
        width: 420,
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: et.cardSurface,
          borderRadius: AppRadius.mdAll,
          border: Border.all(color: et.surfaceBorder),
        ),
        child: content,
      ),
    );
  }
}

class _RegionErrorState extends StatelessWidget {
  const _RegionErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppErrorBox(message),
            const SizedBox(height: AppSpacing.md),
            AppButton.secondary(
              'Tentar novamente',
              onPressed: onRetry,
              width: 200,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Create region dialog
// ---------------------------------------------------------------------------

class _CreateRegionDialog extends ConsumerStatefulWidget {
  const _CreateRegionDialog({
    required this.onConfirm,
    required this.checkName,
  });

  final Future<bool> Function(String name) onConfirm;
  final Future<bool> Function(String name) checkName;

  @override
  ConsumerState<_CreateRegionDialog> createState() =>
      _CreateRegionDialogState();
}

class _CreateRegionDialogState extends ConsumerState<_CreateRegionDialog> {
  final _controller = TextEditingController();
  bool _submitted = false;
  AsyncAction<void> _action = const ActionIdle();
  String? _nameError;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String? _validate(String? value) {
    if (!_submitted) return null;
    if (value == null || value.trim().isEmpty) {
      return 'Informe o nome da região.';
    }
    if (value.trim().length < 2) return 'Nome muito curto.';
    return _nameError;
  }

  Future<void> _submit() async {
    setState(() {
      _submitted = true;
      _nameError = null;
    });
    final name = _controller.text.trim();
    if (name.isEmpty || name.length < 2) return;

    setState(() => _action = const ActionLoading());

    final available = await widget.checkName(name);
    if (!available) {
      setState(() {
        _nameError = 'Já existe uma região com este nome.';
        _action = const ActionIdle();
      });
      return;
    }

    final ok = await widget.onConfirm(name);
    if (!mounted) return;

    if (ok) {
      Navigator.of(context).pop();
    } else {
      setState(
        () => _action = ActionFailure('Não foi possível criar a região.'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final et = EanTrackTheme.of(context);
    final isLoading = _action.isLoading;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final dialogWidth = screenWidth > 1024
        ? 520.0
        : screenWidth > 600
            ? screenWidth * 0.9
            : screenWidth * 0.95;

    return Material(
      color: Colors.transparent,
      child: PopScope(
        canPop: !isLoading,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: isLoading ? null : () => Navigator.of(context).pop(),
          child: Center(
            child: GestureDetector(
              onTap: () {},
              child: Container(
                width: dialogWidth,
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: et.cardSurface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [AppShadows.xl],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nova Região',
                      style: AppTextStyles.headlineSmall.copyWith(
                        color: et.primaryText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Crie uma região para organizar territórios, supervisores e equipes.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: et.secondaryText,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    if (_action.isFailure) ...[
                      AppErrorBox(_action.errorMessage!),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    TextField(
                      controller: _controller,
                      autofocus: true,
                      textCapitalization: TextCapitalization.words,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: et.primaryText,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Nome da Região',
                        errorText: _submitted ? _validate(_controller.text) : null,
                        filled: true,
                        fillColor: et.inputFill,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.md,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: et.inputBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: et.inputBorderFocused,
                            width: 1.5,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.error),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.error,
                            width: 1.5,
                          ),
                        ),
                      ),
                      onChanged: (_) {
                        if (_submitted) setState(() => _nameError = null);
                      },
                      onSubmitted: isLoading ? null : (_) => _submit(),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        SizedBox(
                          width: 120,
                          child: AppButton.secondary(
                            'Cancelar',
                            onPressed: isLoading
                                ? null
                                : () => Navigator.of(context).pop(),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        SizedBox(
                          width: 160,
                          child: AppButton.primary(
                            'Criar Região',
                            onPressed: isLoading ? null : _submit,
                            isLoading: isLoading,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _citiesText(int count) {
  return '$count ${count == 1 ? 'cidade' : 'cidades'}';
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

String _agencyHandleFromName(String agencyName) {
  return agencyName
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '');
}
