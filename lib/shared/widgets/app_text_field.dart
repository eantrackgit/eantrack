import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.focusNode,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.textInputAction = TextInputAction.next,
    this.keyboardType = TextInputType.text,
    this.isPassword = false,
    this.readOnly = false,
    this.inputFormatters,
    this.maxLength,
    this.autofillHints,
  });

  final String label;
  final String? hint;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onFieldSubmitted;
  final TextInputAction textInputAction;
  final TextInputType keyboardType;
  final bool isPassword;
  final bool readOnly;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final Iterable<String>? autofillHints;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _obscure = true;
  FocusNode? _ownedFocus;
  bool _hasFocus = false;

  FocusNode get _focus => widget.focusNode ?? (_ownedFocus ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(AppTextField old) {
    super.didUpdateWidget(old);
    if (old.focusNode != widget.focusNode) {
      (old.focusNode ?? _ownedFocus)?.removeListener(_onFocusChange);
      _focus.addListener(_onFocusChange);
    }
  }

  void _onFocusChange() => setState(() => _hasFocus = _focus.hasFocus);

  @override
  void dispose() {
    _focus.removeListener(_onFocusChange);
    _ownedFocus?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final labelColor = _hasFocus ? AppColors.secondary : AppColors.secondaryText;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        borderRadius: AppRadius.smAll,
        boxShadow: _hasFocus
            ? [
                BoxShadow(
                  color: AppColors.secondary.withOpacity(0.08),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                )
              ]
            : [],
      ),
      child: TextFormField(
        focusNode: _focus,
        controller: widget.controller,
        validator: widget.validator,
        onChanged: widget.onChanged,
        onFieldSubmitted: widget.onFieldSubmitted,
        textInputAction: widget.textInputAction,
        keyboardType: widget.keyboardType,
        obscureText: widget.isPassword && _obscure,
        readOnly: widget.readOnly,
        inputFormatters: widget.inputFormatters,
        maxLength: widget.maxLength,
        autofillHints: widget.autofillHints,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        style: AppTextStyles.bodyMedium,
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: widget.hint,
          counterText: '',
          filled: true,
          fillColor: AppColors.secondaryBackground,
          labelStyle: AppTextStyles.labelMedium.copyWith(color: labelColor),
          enabledBorder: OutlineInputBorder(
            borderRadius: AppRadius.smAll,
            borderSide: const BorderSide(color: AppColors.alternate),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: AppRadius.smAll,
            borderSide:
                const BorderSide(color: AppColors.secondary, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: AppRadius.smAll,
            borderSide: const BorderSide(color: AppColors.error),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: AppRadius.smAll,
            borderSide: const BorderSide(color: AppColors.error, width: 1.5),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: AppRadius.smAll,
            borderSide: const BorderSide(color: AppColors.alternate),
          ),
          suffixIcon: widget.isPassword
              ? IconButton(
                  icon: Icon(
                    _obscure ? Icons.visibility_off : Icons.visibility,
                    color: AppColors.secondaryText,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                )
              : null,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Validators (stateless helpers)
// ---------------------------------------------------------------------------

abstract final class AppValidators {
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Informe o e-mail.';
    final regex =
        RegExp(r'^[\w\.\-]+@[\w\-]+\.[a-z]{2,}$', caseSensitive: false);
    if (!regex.hasMatch(value.trim())) return 'E-mail inv\u00E1lido.';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Informe a senha.';
    if (value.length < 8) return 'M\u00EDnimo 8 caracteres.';
    return null;
  }

  static String? newPassword(String? value) {
    if (value == null || value.isEmpty) return 'Informe a senha.';
    if (value.length < 8) return 'M\u00EDnimo 8 caracteres.';
    if (!value.contains(RegExp(r'[A-Z]')))
      return 'Inclua uma letra mai\u00FAscula.';
    if (!value.contains(RegExp(r'[a-z]')))
      return 'Inclua uma letra min\u00FAscula.';
    return null;
  }

  static String? Function(String?) confirmPassword(
      TextEditingController passwordController) {
    return (value) {
      if (value == null || value.isEmpty) return 'Confirme a senha.';
      if (value != passwordController.text) return 'As senhas n\u00E3o coincidem.';
      return null;
    };
  }

  static String? Function(String?) required(String label) {
    return (String? value) =>
        (value == null || value.trim().isEmpty) ? 'Informe $label.' : null;
  }
}
