import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/shared.dart';
import '../../domain/validity_model.dart';
import '../../domain/validity_state.dart';
import '../providers/validity_provider.dart';

enum _Tab { proximoVencimento, vencidos, avarias }

class ValidityListScreen extends ConsumerStatefulWidget {
  const ValidityListScreen({super.key});

  @override
  ConsumerState<ValidityListScreen> createState() => _ValidityListScreenState();
}

class _ValidityListScreenState extends ConsumerState<ValidityListScreen> {
  _Tab _tab = _Tab.proximoVencimento;
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final et = EanTrackTheme.of(context);
    final validityState = ref.watch(validityNotifierProvider);

    return Scaffold(
      backgroundColor: et.scaffoldOuter,
      appBar: AppBar(
        backgroundColor: et.scaffoldOuter,
        foregroundColor: et.primaryText,
        elevation: 0,
        title: Text(
          'Hist\u00f3ricos de lan\u00e7amento',
          style: AppTextStyles.titleMedium.copyWith(color: et.primaryText),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            color: et.primaryText,
            onPressed: () =>
                ref.read(validityNotifierProvider.notifier).refresh(),
          ),
        ],
      ),
      body: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: ColoredBox(
          color: et.cardSurface,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.sm,
              AppSpacing.sm,
              AppSpacing.sm,
              AppSpacing.sm + MediaQuery.paddingOf(context).bottom,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Color.lerp(et.surface, Colors.white, 0.08),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: et.surfaceBorder.withValues(alpha: 0.7),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.sm,
                      AppSpacing.md,
                      0,
                    ),
                    child: Text(
                      'Seus lan\u00e7amentos',
                      style: AppTextStyles.titleSmall.copyWith(
                        color: et.primaryText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  _SearchBar(onChanged: (v) => setState(() => _search = v)),
                  Expanded(
                    child: _Body(
                      state: validityState,
                      tab: _tab,
                      search: _search,
                      onRetry: () =>
                          ref.read(validityNotifierProvider.notifier).refresh(),
                    ),
                  ),
                  _TabBar(
                    selected: _tab,
                    onChanged: (t) => setState(() => _tab = t),
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

// ---------------------------------------------------------------------------
// Body
// ---------------------------------------------------------------------------

class _Body extends StatelessWidget {
  const _Body({
    required this.state,
    required this.tab,
    required this.search,
    required this.onRetry,
  });

  final ValidityState state;
  final _Tab tab;
  final String search;
  final VoidCallback onRetry;

  List<ValidityModel> _filter(List<ValidityModel> items) {
    var result = switch (tab) {
      _Tab.proximoVencimento =>
        items.where((e) => !e.isExpired && !e.isAvaria).toList(),
      _Tab.vencidos =>
        items.where((e) => e.isExpired && !e.isAvaria).toList(),
      _Tab.avarias => items.where((e) => e.isAvaria).toList(),
    };

    if (search.trim().isNotEmpty) {
      final q = search.toLowerCase();
      result = result
          .where(
            (e) =>
                e.productName.toLowerCase().contains(q) ||
                e.brand.toLowerCase().contains(q) ||
                e.barcode.contains(q) ||
                e.storeName.toLowerCase().contains(q),
          )
          .toList();
    }

    return result..sort((a, b) => a.daysRemaining.compareTo(b.daysRemaining));
  }

  Map<int, List<ValidityModel>> _group(List<ValidityModel> items) {
    final map = <int, List<ValidityModel>>{};
    for (final item in items) {
      (map[item.daysRemaining] ??= []).add(item);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final items = state is ValidityLoaded
        ? _filter((state as ValidityLoaded).items)
        : <ValidityModel>[];

    final groups = _group(items);

    return AppListStateView(
      isLoading: state is ValidityLoading || state is ValidityInitial,
      errorMessage:
          state is ValidityError ? (state as ValidityError).message : null,
      onRetry: onRetry,
      isEmpty: state is ValidityLoaded && groups.isEmpty,
      emptyIcon: Icons.inventory_2_outlined,
      emptyTitle: 'Nenhum lanÃ§amento',
      emptySubtitle: 'Adicione produtos para visualizar aqui.',
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        itemCount: groups.length,
        itemBuilder: (context, i) {
          final days = groups.keys.elementAt(i);
          final groupItems = groups.values.elementAt(i);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _GroupHeader(daysRemaining: days),
              ...groupItems.map((item) => _ItemCard(item: item)),
            ],
          );
        },
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
    final et = EanTrackTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: onChanged,
              style: AppTextStyles.bodyMedium.copyWith(color: et.primaryText),
              decoration: InputDecoration(
                hintText: 'Pesquisar',
                hintStyle: AppTextStyles.bodyMedium.copyWith(
                  color: et.secondaryText,
                ),
                prefixIcon: Icon(Icons.search, color: et.secondaryText),
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
                  borderSide:
                      BorderSide(color: et.inputBorderFocused, width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: et.inputFill,
              borderRadius: AppRadius.smAll,
              border: Border.all(color: et.inputBorder),
            ),
            child: Icon(Icons.tune, color: et.secondaryText, size: 20),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Group header
// ---------------------------------------------------------------------------

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.daysRemaining});
  final int daysRemaining;

  Color _color() {
    if (daysRemaining < 0) return AppColors.error;
    if (daysRemaining <= 7) return AppColors.error;
    if (daysRemaining <= 30) return AppColors.warning;
    return AppColors.success;
  }

  String _label() {
    if (daysRemaining < 0) {
      final abs = daysRemaining.abs();
      return 'Vencido hÃ¡ $abs ${abs == 1 ? 'Dia' : 'Dias'}';
    }
    if (daysRemaining == 0) return 'Vence Hoje';
    return 'Dias Restantes $daysRemaining ${daysRemaining == 1 ? 'Dia' : 'Dias'}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs + 2,
      ),
      color: _color(),
      child: Text(
        _label(),
        style: AppTextStyles.labelSmall.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Item card
// ---------------------------------------------------------------------------

class _ItemCard extends StatelessWidget {
  const _ItemCard({required this.item});
  final ValidityModel item;

  Color _validityColor() {
    final days = item.daysRemaining;
    if (days < 0) return AppColors.error;
    if (days <= 7) return AppColors.error;
    if (days <= 30) return AppColors.warning;
    return AppColors.success;
  }

  String _formatDate(DateTime date) {
    const months = [
      'jan.', 'fev.', 'mar.', 'abr.', 'mai.', 'jun.',
      'jul.', 'ago.', 'set.', 'out.', 'nov.', 'dez.',
    ];
    const weekdays = [
      'dom.', 'seg.', 'ter.', 'qua.', 'qui.', 'sex.', 'sÃ¡b.',
    ];
    final wd = weekdays[date.weekday % 7];
    return '$wd, ${date.day} de ${months[date.month - 1]}';
  }

  String _fmt(double value) =>
      'R\$${value.toStringAsFixed(2).replaceAll('.', ',')}';

  @override
  Widget build(BuildContext context) {
    final et = EanTrackTheme.of(context);
    final cardColor = Color.lerp(et.surface, Colors.white, 0.06) ?? et.surface;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: AppRadius.smAll,
        border: Border.all(color: et.surfaceBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ProductImage(imageUrl: item.imageUrl, barcode: item.barcode),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: et.primaryText,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.storeName,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: et.secondaryText,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Quantidade: ${item.quantity}${item.quantityUnit}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: et.secondaryText,
                  ),
                ),
                Text(
                  'PreÃ§o:ATC ${_fmt(item.priceAtc)}/VR.JR${_fmt(item.priceVrJr)}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: et.secondaryText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Validade:${_formatDate(item.validityDate)}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: _validityColor(),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Icon(Icons.edit_outlined, size: 18, color: et.secondaryText),
              const SizedBox(height: 2),
              Text(
                'Editar',
                style: AppTextStyles.bodySmall.copyWith(
                  color: et.secondaryText,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  const _ProductImage({required this.imageUrl, required this.barcode});
  final String? imageUrl;
  final String barcode;

  @override
  Widget build(BuildContext context) {
    final et = EanTrackTheme.of(context);
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: et.inputFill,
            borderRadius: AppRadius.smAll,
            border: Border.all(color: et.surfaceBorder),
          ),
          child: imageUrl != null
              ? ClipRRect(
                  borderRadius: AppRadius.smAll,
                  child: Image.network(
                    imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.image_not_supported_outlined,
                      color: et.secondaryText,
                      size: 24,
                    ),
                  ),
                )
              : Icon(
                  Icons.inventory_2_outlined,
                  color: et.secondaryText,
                  size: 28,
                ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: 60,
          child: Text(
            barcode,
            style: AppTextStyles.bodySmall.copyWith(
              color: et.secondaryText,
              fontSize: 8,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom tab bar
// ---------------------------------------------------------------------------

class _TabBar extends StatelessWidget {
  const _TabBar({required this.selected, required this.onChanged});
  final _Tab selected;
  final ValueChanged<_Tab> onChanged;

  @override
  Widget build(BuildContext context) {
    final et = EanTrackTheme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.xs,
        AppSpacing.sm,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          _TabButton(
            label: 'Vencimento Pr\u00f3ximo',
            selected: selected == _Tab.proximoVencimento,
            selectedColor: et.ctaBackground,
            onTap: () => onChanged(_Tab.proximoVencimento),
          ),
          const SizedBox(width: AppSpacing.xs),
          _TabButton(
            label: 'Vencidos',
            selected: selected == _Tab.vencidos,
            selectedColor: AppColors.error,
            onTap: () => onChanged(_Tab.vencidos),
          ),
          const SizedBox(width: AppSpacing.xs),
          _TabButton(
            label: 'Avarias',
            selected: selected == _Tab.avarias,
            selectedColor: AppColors.error,
            onTap: () => onChanged(_Tab.avarias),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.selected,
    required this.selectedColor,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color selectedColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final et = EanTrackTheme.of(context);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: selected ? selectedColor : et.inputFill,
            borderRadius: AppRadius.smAll,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.labelSmall.copyWith(
              color: selected ? Colors.white : et.secondaryText,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }
}
