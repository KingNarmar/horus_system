import 'package:horus_system/features/auth/domain/policies/password_policy.dart';
import 'package:test/test.dart';

void main() {
  group('PasswordPolicy', () {
    test('counts Unicode code points for the 15-character minimum', () {
      expect(PasswordPolicy.minimumLength, 15);
      expect(
        PasswordPolicy.validateForCreation('12345678901234'),
        PasswordCreationValidation.tooShort,
      );
      expect(
        PasswordPolicy.validateForCreation('123456789012345'),
        PasswordCreationValidation.valid,
      );
      expect(
        PasswordPolicy.validateForCreation(List.filled(14, '🔒').join()),
        PasswordCreationValidation.tooShort,
      );
      expect(
        PasswordPolicy.validateForCreation(List.filled(15, '🔒').join()),
        PasswordCreationValidation.valid,
      );
    });

    test('allows spaces, punctuation, and 64 ASCII characters', () {
      expect(
        PasswordPolicy.isValidForCreation('a long passphrase with spaces!'),
        isTrue,
      );
      expect(
        PasswordPolicy.isValidForCreation(List.filled(64, 'a').join()),
        isTrue,
      );
    });

    test('enforces the Supabase 72 UTF-8 byte maximum', () {
      expect(PasswordPolicy.maximumUtf8Bytes, 72);
      expect(
        PasswordPolicy.validateForCreation(List.filled(72, 'a').join()),
        PasswordCreationValidation.valid,
      );
      expect(
        PasswordPolicy.validateForCreation(List.filled(73, 'a').join()),
        PasswordCreationValidation.tooLong,
      );
      expect(
        PasswordPolicy.validateForCreation(List.filled(18, '🔒').join()),
        PasswordCreationValidation.valid,
      );
      expect(
        PasswordPolicy.validateForCreation(List.filled(19, '🔒').join()),
        PasswordCreationValidation.tooLong,
      );
    });

    test('does not silently claim 64 multibyte Unicode characters fit', () {
      expect(
        PasswordPolicy.validateForCreation(List.filled(64, '🔒').join()),
        PasswordCreationValidation.tooLong,
      );
    });
  });
}
