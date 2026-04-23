import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';

/// Card base do EANTrack.
///
/// Uso simples (informacional):
///   AppCard(child: ...)
///
/// Uso em card auth/onboarding (fundo branco):
///   AppCard(color: AppColors.secondaryBackground, child: ...)
///
/// Uso selecionável (ex: seleção de modo, item de lista):
///   AppCard(
///     selected: _selectedId == item.id,
///     onTap: () => setState(() => _selectedId = item.id),
///     child: ...,
///   )
///
/// Uso com borda customizada:
///   AppCard(borderColor: AppColors.actionBlue, child: ...)
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.color,
    this.padding,
    this.onTap,
    this.selected = false,
    this.borderColor,
  });

  final Widget child;

  /// Cor de fundo. Padrão: [AppColors.primaryBackground].
  final Color? color;

  /// Padding interno. Padrão: [AppSpacing.lg] em todos os lados.
  final EdgeInsetsGeometry? padding;

  /// Se fornecido, o card responde ao toque com ripple effect.
  final VoidCallback? onTap;

  /// Se true, exibe borda [AppColors.success] com 2px (estado selecionado).
  final bool selected;

  /// Cor de borda customizada. Sobrescreve a lógica de [selected].
  /// Se null e [selected] = false, sem borda visível.
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final et = EanTrackTheme.of(context);

    final Color effectiveBorderColor = borderColor ??
        (selected ? AppColors.success : Colors.transparent);
    final double effectiveBorderWidth = selected ? 2.0 : 1.0;
    final Color effectiveColor = color ?? (isDark ? et.cardSurface : AppColors.primaryBackground);
    final EdgeInsetsGeometry effectivePadding =
        padding ?? const EdgeInsets.all(AppSpacing.lg);
    final List<BoxShadow> shadow = isDark
        ? [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.40),
              blurRadius: 28,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: AppColors.cardGlow.withValues(alpha: 0.06),
              blurRadius: 40,
              spreadRadius: -4,
              offset: const Offset(0, 4),
            ),
          ]
        : [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ];

    final deco = BoxDecoration(
      color: effectiveColor,
      borderRadius: AppRadius.lgAll,
      boxShadow: shadow,
      border: Border.all(
        color: effectiveBorderColor,
        width: effectiveBorderWidth,
      ),
    );

    // Margem horizontal padrão — fica fora da área tappable
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: onTap == null
          ? Container(
              width: double.infinity,
              padding: effectivePadding,
              decoration: deco,
              child: child,
            )
          : Material(
              color: Colors.transparent,
              borderRadius: AppRadius.lgAll,
              child: InkWell(
                borderRadius: AppRadius.lgAll,
                onTap: onTap,
                child: Ink(
                  decoration: deco,
                  child: Padding(
                    padding: effectivePadding,
                    child: child,
                  ),
                ),
              ),
            ),
    );
  }
}
