import 'string_utils.dart';

bool isValidCnpj(String cnpj) {
  final value = onlyDigits(cnpj);
  if (value.length != 14) return false;
  if (RegExp(r'^(\d)\1{13}$').hasMatch(value)) return false;

  final numbers = value.split('').map(int.parse).toList(growable: false);
  final firstDigit = _calculateDigit(
    numbers,
    const [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2],
  );
  final secondDigit = _calculateDigit(
    numbers,
    const [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2],
  );

  return numbers[12] == firstDigit && numbers[13] == secondDigit;
}

String formatCnpj(String cnpj) {
  final digits = onlyDigits(cnpj);
  if (digits.length != 14) return digits;

  return '${digits.substring(0, 2)}.${digits.substring(2, 5)}.'
      '${digits.substring(5, 8)}/${digits.substring(8, 12)}-'
      '${digits.substring(12, 14)}';
}

int _calculateDigit(List<int> numbers, List<int> weights) {
  var sum = 0;
  for (var i = 0; i < weights.length; i++) {
    sum += numbers[i] * weights[i];
  }

  final remainder = sum % 11;
  return remainder < 2 ? 0 : 11 - remainder;
}
