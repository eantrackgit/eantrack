import 'package:flutter_test/flutter_test.dart';
import 'package:eantrack/shared/utils/password_validator.dart';

void main() {
  group('PasswordValidator', () {
    group('hasUppercase', () {
      test('returns true when string contains uppercase letter', () {
        expect(PasswordValidator.hasUppercase('Abc123!'), isTrue);
      });

      test('returns false when string has no uppercase letter', () {
        expect(PasswordValidator.hasUppercase('abc123!'), isFalse);
      });
    });

    group('hasLowercase', () {
      test('returns true when string contains lowercase letter', () {
        expect(PasswordValidator.hasLowercase('ABC123!a'), isTrue);
      });

      test('returns false when string has no lowercase letter', () {
        expect(PasswordValidator.hasLowercase('ABC123!'), isFalse);
      });
    });

    group('hasNumber', () {
      test('returns true when string contains a digit', () {
        expect(PasswordValidator.hasNumber('Abc1!'), isTrue);
      });

      test('returns false when string has no digit', () {
        expect(PasswordValidator.hasNumber('Abcdef!'), isFalse);
      });
    });

    group('hasSymbol', () {
      test('returns true for @', () {
        expect(PasswordValidator.hasSymbol('Abc1@xyz'), isTrue);
      });

      test('returns true for #', () {
        expect(PasswordValidator.hasSymbol('Abc1#xyz'), isTrue);
      });

      test('returns true for \$', () {
        expect(PasswordValidator.hasSymbol(r'Abc1$xyz'), isTrue);
      });

      test('returns true for %', () {
        expect(PasswordValidator.hasSymbol('Abc1%xyz'), isTrue);
      });

      test('returns false when password has no symbol', () {
        expect(PasswordValidator.hasSymbol('Abc12345'), isFalse);
      });

      test('returns false for empty string', () {
        expect(PasswordValidator.hasSymbol(''), isFalse);
      });
    });

    group('hasMinLength', () {
      test('returns true for 8 characters', () {
        expect(PasswordValidator.hasMinLength('12345678'), isTrue);
      });

      test('returns true for more than 8 characters', () {
        expect(PasswordValidator.hasMinLength('123456789'), isTrue);
      });

      test('returns false for 7 characters', () {
        expect(PasswordValidator.hasMinLength('1234567'), isFalse);
      });
    });

    group('isValid', () {
      test('returns true for password meeting all rules', () {
        expect(PasswordValidator.isValid('Senha@123'), isTrue);
      });

      test('returns false when missing symbol', () {
        expect(PasswordValidator.isValid('Senha1234'), isFalse);
      });

      test('returns false when missing uppercase', () {
        expect(PasswordValidator.isValid('senha@123'), isFalse);
      });

      test('returns false when missing lowercase', () {
        expect(PasswordValidator.isValid('SENHA@123'), isFalse);
      });

      test('returns false when missing number', () {
        expect(PasswordValidator.isValid('Senha@abc'), isFalse);
      });

      test('returns false when too short', () {
        expect(PasswordValidator.isValid('Se@1abc'), isFalse);
      });

      test('returns false for empty string', () {
        expect(PasswordValidator.isValid(''), isFalse);
      });
    });
  });
}
