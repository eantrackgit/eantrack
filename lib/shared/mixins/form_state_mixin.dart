import 'package:flutter/widgets.dart';

import '../utils/password_validator.dart';

/// Mixin que centraliza o estado padrão de formulários do EANTrack.
///
/// Uso:
///   class _MyScreenState extends ConsumerState<MyScreen>
///       with FormStateMixin<MyScreen> { ... }
///
/// Fornece:
/// - [formKey] + [submitted] para validação pós-submit
/// - [emailValidator], [passwordValidator], [confirmValidator], [requiredValidator]
/// - Rastreamento de força de senha em tempo real (5 regras)
/// - Rastreamento de confirmação de senha em tempo real
mixin FormStateMixin<T extends StatefulWidget> on State<T> {
  final formKey = GlobalKey<FormState>();
  bool submitted = false;

  // ---------- força de senha ----------
  bool hasMinLength = false;
  bool hasUppercase = false;
  bool hasLowercase = false;
  bool hasDigit = false;
  bool hasSymbol = false;
  bool isTypingPassword = false;

  /// Senha válida quando atende TODAS as 5 regras.
  bool get passwordValid =>
      hasMinLength && hasUppercase && hasLowercase && hasDigit && hasSymbol;

  // ---------- confirmação de senha ----------
  bool isConfirmTyping = false;
  bool passwordsMatch = false;

  // ---------------------------------------------------------------------------
  // Chamado no onChanged do campo de senha
  // ---------------------------------------------------------------------------
  void onPasswordChanged(String value, [TextEditingController? confirmCtrl]) {
    setState(() {
      isTypingPassword = value.isNotEmpty;
      hasMinLength = PasswordValidator.hasMinLength(value);
      hasUppercase = PasswordValidator.hasUppercase(value);
      hasLowercase = PasswordValidator.hasLowercase(value);
      hasDigit = PasswordValidator.hasNumber(value);
      hasSymbol = PasswordValidator.hasSymbol(value);
      if (isConfirmTyping && confirmCtrl != null) {
        passwordsMatch =
            confirmCtrl.text == value && confirmCtrl.text.isNotEmpty;
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Chamado no onChanged do campo de confirmar senha
  // ---------------------------------------------------------------------------
  void onConfirmChanged(String value, TextEditingController passwordCtrl) {
    setState(() {
      isConfirmTyping = value.isNotEmpty;
      passwordsMatch = value == passwordCtrl.text && value.isNotEmpty;
    });
  }

  // ---------------------------------------------------------------------------
  // Aciona submitted + valida. Retorna true se válido.
  // ---------------------------------------------------------------------------
  bool validateAndSubmit() {
    setState(() => submitted = true);
    return formKey.currentState!.validate();
  }

  // ---------------------------------------------------------------------------
  // Validators padrão (respeitam submitted)
  // ---------------------------------------------------------------------------
  String? emailValidator(String? value) {
    if (!submitted) return null;
    if (value == null || value.trim().isEmpty) return 'Informe o e-mail.';
    final regex =
        RegExp(r'^[\w\.\-]+@[\w\-]+\.[a-z]{2,}$', caseSensitive: false);
    if (!regex.hasMatch(value.trim())) return 'E-mail inv\u00E1lido.';
    return null;
  }

  String? passwordValidator(String? value) {
    if (!submitted) return null;
    if (value == null || value.isEmpty) return 'Informe a senha.';
    return null;
  }

  String? confirmValidator(String? value, TextEditingController passwordCtrl) {
    if (!submitted) return null;
    if (value == null || value.isEmpty) return 'Confirme a senha.';
    if (value != passwordCtrl.text) return 'As senhas n\u00E3o coincidem.';
    return null;
  }

  String? requiredValidator(String? value, String fieldName) {
    if (!submitted) return null;
    if (value == null || value.trim().isEmpty) return 'Informe $fieldName.';
    return null;
  }
}
