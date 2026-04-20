/// Retorna apenas os dígitos de [value], removendo qualquer outro caractere.
String onlyDigits(String value) {
  return value.replaceAll(RegExp(r'\D'), '');
}

/// Retorna `true` quando [value] é um endereço de e-mail válido no formato básico.
bool isValidEmail(String value) {
  final email = value.trim();
  if (email.isEmpty) return false;
  return RegExp(r'^[\w.\-]+@[\w\-]+\.[a-z]{2,}$', caseSensitive: false)
      .hasMatch(email);
}
