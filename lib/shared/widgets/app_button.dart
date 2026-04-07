import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Variantes visuais do AppButton.
///
/// - [primary]  → navy preenchido (CTA principal)
/// - [secondary] → outlined navy (ação secundária, ex: "Voltar")
/// - [outlined]  → alias de secondary (semântica idêntica)
/// - [action]   → azul preenchido (consultas de API: CNPJ, CEP)
/// - [social]   → vermelho preenchido (login Google / social)
enum AppButtonVariant { primary, secondary, outlined, action, social }

class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.variant = AppButtonVariant.primary,
    this.width,
    this.leadingIcon,
    this.trailingIcon,
  });

  // ---------------------------------------------------------------------------
  // Named constructors — forma recomendada de uso
  // ---------------------------------------------------------------------------

  /// Botão CTA principal: navy preenchido + texto branco.
  factory AppButton.primary(
    String label, {
    Key? key,
    VoidCallback? onPressed,
    bool isLoading = false,
    double? width,
    Widget? leadingIcon,
    Widget? trailingIcon,
  }) =>
      AppButton(
        key: key,
        label: label,
        onPressed: onPressed,
        isLoading: isLoading,
        variant: AppButtonVariant.primary,
        width: width,
        leadingIcon: leadingIcon,
        trailingIcon: trailingIcon,
      );

  /// Botão secundário: outlined navy + texto navy. Ideal para "Voltar", "Cancelar".
  factory AppButton.secondary(
    String label, {
    Key? key,
    VoidCallback? onPressed,
    bool isLoading = false,
    double? width,
    Widget? leadingIcon,
    Widget? trailingIcon,
  }) =>
      AppButton(
        key: key,
        label: label,
        onPressed: onPressed,
        isLoading: isLoading,
        variant: AppButtonVariant.secondary,
        width: width,
        leadingIcon: leadingIcon,
        trailingIcon: trailingIcon,
      );

  /// Alias explícito para [secondary] — mesmo visual.
  factory AppButton.outlined(
    String label, {
    Key? key,
    VoidCallback? onPressed,
    bool isLoading = false,
    double? width,
    Widget? leadingIcon,
    Widget? trailingIcon,
  }) =>
      AppButton(
        key: key,
        label: label,
        onPressed: onPressed,
        isLoading: isLoading,
        variant: AppButtonVariant.outlined,
        width: width,
        leadingIcon: leadingIcon,
        trailingIcon: trailingIcon,
      );

  /// Botão de ação API: azul preenchido. Usar em "Consultar CNPJ", "Buscar CEP".
  factory AppButton.action(
    String label, {
    Key? key,
    VoidCallback? onPressed,
    bool isLoading = false,
    double? width,
    Widget? leadingIcon,
    Widget? trailingIcon,
  }) =>
      AppButton(
        key: key,
        label: label,
        onPressed: onPressed,
        isLoading: isLoading,
        variant: AppButtonVariant.action,
        width: width,
        leadingIcon: leadingIcon,
        trailingIcon: trailingIcon,
      );

  /// Botão social: vermelho preenchido. Usar para login Google.
  factory AppButton.social(
    String label, {
    Key? key,
    VoidCallback? onPressed,
    bool isLoading = false,
    double? width,
    Widget? leadingIcon,
    Widget? trailingIcon,
  }) =>
      AppButton(
        key: key,
        label: label,
        onPressed: onPressed,
        isLoading: isLoading,
        variant: AppButtonVariant.social,
        width: width,
        leadingIcon: leadingIcon,
        trailingIcon: trailingIcon,
      );

  // ---------------------------------------------------------------------------

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final AppButtonVariant variant;
  final double? width;
  final Widget? leadingIcon;
  final Widget? trailingIcon;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _pressed = false;

  bool get _disabled => widget.onPressed == null || widget.isLoading;

  void _onTapDown(TapDownDetails _) {
    if (!_disabled) setState(() => _pressed = true);
  }

  void _onTapUp(TapUpDetails _) => setState(() => _pressed = false);
  void _onTapCancel() => setState(() => _pressed = false);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        child: AnimatedOpacity(
          opacity: _disabled ? 0.65 : 1.0,
          duration: const Duration(milliseconds: 150),
          child: SizedBox(
            width: widget.width ?? double.infinity,
            height: 52,
            child: _buildButton(),
          ),
        ),
      ),
    );
  }

  Widget _buildButton() {
    switch (widget.variant) {
      case AppButtonVariant.primary:
        return ElevatedButton(
          onPressed: _disabled ? null : widget.onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.secondary,
            disabledBackgroundColor: AppColors.secondary,
            foregroundColor: AppColors.secondaryBackground,
            shape: RoundedRectangleBorder(borderRadius: AppRadius.smAll),
            elevation: 0,
          ),
          child: _content(AppColors.secondaryBackground),
        );

      case AppButtonVariant.secondary:
      case AppButtonVariant.outlined:
        return OutlinedButton(
          onPressed: _disabled ? null : widget.onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.secondary,
            disabledForegroundColor: AppColors.secondary,
            side: const BorderSide(color: AppColors.secondary, width: 1.5),
            shape: RoundedRectangleBorder(borderRadius: AppRadius.smAll),
          ),
          child: _content(AppColors.secondary),
        );

      case AppButtonVariant.action:
        return ElevatedButton(
          onPressed: _disabled ? null : widget.onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.actionBlue,
            disabledBackgroundColor: AppColors.actionBlue,
            foregroundColor: AppColors.secondaryBackground,
            shape: RoundedRectangleBorder(borderRadius: AppRadius.smAll),
            elevation: 0,
          ),
          child: _content(AppColors.secondaryBackground),
        );

      case AppButtonVariant.social:
        return ElevatedButton(
          onPressed: _disabled ? null : widget.onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            disabledBackgroundColor: AppColors.primary,
            foregroundColor: AppColors.secondaryBackground,
            shape: RoundedRectangleBorder(borderRadius: AppRadius.smAll),
            elevation: 0,
          ),
          child: _content(AppColors.secondaryBackground),
        );
    }
  }

  Widget _content(Color color) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.75, end: 1.0).animate(animation),
          child: child,
        ),
      ),
      child: widget.isLoading
          ? SizedBox(
              key: const ValueKey('loading'),
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: color,
              ),
            )
          : _labelContent(color),
    );
  }

  Widget _labelContent(Color color) {
    if (widget.leadingIcon != null || widget.trailingIcon != null) {
      return Row(
        key: ValueKey(widget.label),
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.leadingIcon != null) ...[
            widget.leadingIcon!,
            const SizedBox(width: AppSpacing.sm),
          ],
          Text(widget.label,
              style: AppTextStyles.titleSmall.copyWith(color: color)),
          if (widget.trailingIcon != null) ...[
            const SizedBox(width: AppSpacing.sm),
            widget.trailingIcon!,
          ],
        ],
      );
    }
    return Text(
      widget.label,
      key: ValueKey(widget.label),
      style: AppTextStyles.titleSmall.copyWith(color: color),
    );
  }
}
