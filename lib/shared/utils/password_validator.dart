/// Validações de força de senha — fonte única de verdade para UI e backend.
///
/// Usado por [FormStateMixin] (feedback visual em tempo real)
/// e por [AuthRepository._validatePassword] (guard server-side).
abstract final class PasswordValidator {
  static bool hasUppercase(String v) => RegExp(r'[A-Z]').hasMatch(v);
  static bool hasLowercase(String v) => RegExp(r'[a-z]').hasMatch(v);
  static bool hasNumber(String v) => RegExp(r'[0-9]').hasMatch(v);
  static bool hasSymbol(String v) =>
      RegExp(r'[!@#\$%^&*()_\-+=\[\]{}|;:,.<>?/~\\"]').hasMatch(v);
  static bool hasMinLength(String v) => v.length >= 8;

  static bool isValid(String v) =>
      hasUppercase(v) &&
      hasLowercase(v) &&
      hasNumber(v) &&
      hasSymbol(v) &&
      hasMinLength(v);
}
