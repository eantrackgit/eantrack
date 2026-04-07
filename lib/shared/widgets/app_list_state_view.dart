import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'app_button.dart';
import 'app_empty_state.dart';
import 'app_error_box.dart';

/// Renderiza os três estados padrão de uma lista assíncrona:
/// loading → empty → error → conteúdo.
///
/// Uso:
/// ```dart
/// AppListStateView(
///   isLoading: state is RegionLoading,
///   errorMessage: state is RegionError ? state.message : null,
///   isEmpty: state is RegionLoaded && state.regions.isEmpty,
///   onRetry: () => ref.read(provider.notifier).load(),
///   emptyIcon: Icons.map_outlined,
///   emptyTitle: 'Nenhuma região encontrada',
///   emptySubtitle: 'Crie uma região para começar.',
///   child: ListView(...),
/// )
/// ```
class AppListStateView extends StatelessWidget {
  const AppListStateView({
    super.key,
    required this.isLoading,
    required this.child,
    this.errorMessage,
    this.onRetry,
    this.isEmpty = false,
    this.emptyIcon = Icons.inbox_outlined,
    this.emptyTitle = 'Nenhum item encontrado',
    this.emptySubtitle,
  });

  final bool isLoading;
  final Widget child;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final bool isEmpty;
  final IconData emptyIcon;
  final String emptyTitle;
  final String? emptySubtitle;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppErrorBox(errorMessage!),
              if (onRetry != null) ...[
                const SizedBox(height: AppSpacing.md),
                AppButton.secondary(
                  'Tentar novamente',
                  onPressed: onRetry,
                  width: 200,
                ),
              ],
            ],
          ),
        ),
      );
    }

    if (isEmpty) {
      return AppEmptyState(
        icon: emptyIcon,
        title: emptyTitle,
        subtitle: emptySubtitle ?? '',
      );
    }

    return child;
  }
}
