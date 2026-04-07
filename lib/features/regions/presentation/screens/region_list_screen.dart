import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/shared.dart';
import '../../../../shared/utils/async_action.dart';
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
  int _tabIndex = 0; // 0=Todos, 1=Ativos, 2=Inativos

  @override
  Widget build(BuildContext context) {
    final regionState = ref.watch(regionNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(
              onAdd: () => _showCreateDialog(context),
            ),
            _TabFilter(
              selectedIndex: _tabIndex,
              onChanged: (i) => setState(() => _tabIndex = i),
            ),
            _SearchBar(
              onChanged: (v) => setState(() => _search = v),
            ),
            Expanded(child: _Body(
              state: regionState,
              search: _search,
              tabIndex: _tabIndex,
              onRetry: () => ref.read(regionNotifierProvider.notifier).load(),
              onToggleActive: (id, active) => ref
                  .read(regionNotifierProvider.notifier)
                  .toggleActive(id, isActive: active),
            )),
          ],
        ),
      ),
    );
  }

  Future<void> _showCreateDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _CreateRegionDialog(
        onConfirm: (name) async {
          final ok = await ref
              .read(regionNotifierProvider.notifier)
              .createRegion(name);
          return ok;
        },
        checkName: (name) => ref
            .read(regionNotifierProvider.notifier)
            .isNameAvailable(name),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

class _Header extends StatelessWidget {
  const _Header({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.sm,
        0,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            color: AppColors.primaryText,
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          Expanded(
            child: Text(
              'Regiões',
              style: AppTextStyles.headlineSmall.copyWith(
                color: AppColors.primaryText,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            color: AppColors.secondary,
            tooltip: 'Nova região',
            onPressed: onAdd,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tab filter
// ---------------------------------------------------------------------------

class _TabFilter extends StatelessWidget {
  const _TabFilter({required this.selectedIndex, required this.onChanged});
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  static const _labels = ['Todos', 'Ativos', 'Inativos'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: List.generate(
          _labels.length,
          (i) => Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: _TabChip(
              label: _labels[i],
              selected: selectedIndex == i,
              onTap: () => onChanged(i),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs + 2,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.secondary : Colors.transparent,
          borderRadius: AppRadius.mdAll,
          border: Border.all(
            color: selected ? AppColors.secondary : AppColors.tertiary,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: selected ? AppColors.info : AppColors.secondaryText,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Search bar
// ---------------------------------------------------------------------------

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.onChanged});
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: TextField(
        onChanged: onChanged,
        style: AppTextStyles.bodyMedium,
        decoration: InputDecoration(
          hintText: 'Buscar região...',
          hintStyle: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.secondaryText,
          ),
          prefixIcon: const Icon(Icons.search, color: AppColors.secondaryText),
          filled: true,
          fillColor: AppColors.secondaryBackground,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          border: OutlineInputBorder(
            borderRadius: AppRadius.smAll,
            borderSide: const BorderSide(color: AppColors.tertiary),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: AppRadius.smAll,
            borderSide: const BorderSide(color: AppColors.tertiary),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: AppRadius.smAll,
            borderSide: const BorderSide(color: AppColors.secondary, width: 1.5),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Body — estados
// ---------------------------------------------------------------------------

class _Body extends StatelessWidget {
  const _Body({
    required this.state,
    required this.search,
    required this.tabIndex,
    required this.onRetry,
    required this.onToggleActive,
  });

  final RegionState state;
  final String search;
  final int tabIndex;
  final VoidCallback onRetry;
  final void Function(String id, bool active) onToggleActive;

  @override
  Widget build(BuildContext context) {
    final regions = state is RegionLoaded
        ? _filter((state as RegionLoaded).regions)
        : <RegionModel>[];

    return AppListStateView(
      isLoading: state is RegionLoading,
      errorMessage: state is RegionError ? (state as RegionError).message : null,
      onRetry: onRetry,
      isEmpty: state is RegionLoaded && regions.isEmpty,
      emptyIcon: Icons.map_outlined,
      emptyTitle: 'Nenhuma região encontrada',
      emptySubtitle: 'Crie uma região para organizar seus territórios.',
      child: _RegionList(regions: regions, onToggleActive: onToggleActive),
    );
  }

  List<RegionModel> _filter(List<RegionModel> regions) {
    var result = regions;

    // Tab filter
    if (tabIndex == 1) result = result.where((r) => r.isActive).toList();
    if (tabIndex == 2) result = result.where((r) => !r.isActive).toList();

    // Search filter
    if (search.trim().isNotEmpty) {
      final q = search.toLowerCase();
      result = result.where((r) => r.name.toLowerCase().contains(q)).toList();
    }

    return result;
  }
}

class _RegionList extends StatelessWidget {
  const _RegionList({required this.regions, required this.onToggleActive});
  final List<RegionModel> regions;
  final void Function(String id, bool active) onToggleActive;

  @override
  Widget build(BuildContext context) {
    if (regions.isEmpty) {
      return const AppEmptyState(
        icon: Icons.map_outlined,
        title: 'Nenhuma região encontrada',
        subtitle: 'Crie uma região para organizar seus territórios.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      itemCount: regions.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (_, i) => _RegionCard(
        region: regions[i],
        onToggleActive: onToggleActive,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Region card
// ---------------------------------------------------------------------------

class _RegionCard extends StatelessWidget {
  const _RegionCard({required this.region, required this.onToggleActive});
  final RegionModel region;
  final void Function(String id, bool active) onToggleActive;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.secondaryBackground,
      borderRadius: AppRadius.mdAll,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.1),
                borderRadius: AppRadius.smAll,
              ),
              child: const Icon(
                Icons.map_outlined,
                size: 20,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    region.name,
                    style: AppTextStyles.titleSmall.copyWith(
                      color: AppColors.primaryText,
                    ),
                  ),
                  Text(
                    '${region.cityCount} ${region.cityCount == 1 ? 'cidade' : 'cidades'}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
            _StatusBadge(isActive: region.isActive),
            const SizedBox(width: AppSpacing.sm),
            _ToggleButton(
              isActive: region.isActive,
              onTap: () => onToggleActive(region.id, !region.isActive),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.isActive});
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.success : AppColors.secondaryText;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        isActive ? 'Ativa' : 'Inativa',
        style: AppTextStyles.labelSmall.copyWith(color: color),
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  const _ToggleButton({required this.isActive, required this.onTap});
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(
        isActive ? Icons.toggle_on : Icons.toggle_off,
        color: isActive ? AppColors.success : AppColors.secondaryText,
        size: 28,
      ),
      tooltip: isActive ? 'Desativar' : 'Ativar',
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

class _CreateRegionDialogState extends ConsumerState<_CreateRegionDialog>
    with SingleTickerProviderStateMixin {
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
    if (value == null || value.trim().isEmpty) return 'Informe o nome da região.';
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

    // Verificar disponibilidade
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
      setState(() => _action = ActionFailure('Não foi possível criar a região.'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nova Região',
              style: AppTextStyles.headlineSmall.copyWith(
                color: AppColors.primaryText,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Defina um nome único para identificar esta região.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.secondaryText,
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
              style: AppTextStyles.bodyMedium,
              decoration: InputDecoration(
                labelText: 'Nome da região',
                errorText: _submitted ? _validate(_controller.text) : null,
                border: OutlineInputBorder(borderRadius: AppRadius.smAll),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AppRadius.smAll,
                  borderSide:
                      const BorderSide(color: AppColors.secondary, width: 1.5),
                ),
              ),
              onChanged: (_) {
                if (_submitted) setState(() => _nameError = null);
              },
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: AppButton.secondary(
                    'Cancelar',
                    onPressed:
                        _action.isLoading ? null : () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: AppButton.primary(
                    'Criar',
                    onPressed: _action.isLoading ? null : _submit,
                    isLoading: _action.isLoading,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
