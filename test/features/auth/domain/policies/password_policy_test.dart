import 'package:horus_system/features/auth/domain/policies/password_policy.dart';
import 'package:test/test.dart';

void main() {
  group('PasswordPolicy', () {
    test('rejects 14 code points and accepts 15', () {
      expect(PasswordPolicy.minimumLength, 15);
      expect(PasswordPolicy.isValidForCreation('12345678901234'), isFalse);
      expect(PasswordPolicy.isValidForCreation('123456789012345'), isTrue);
    });

    test('accepts spaces, punctuation, and 64+ character passphrases', () {
      expect(
        PasswordPolicy.isValidForCreation('a long passphrase with spaces!'),
        isTrue,
      );
      expect(
        PasswordPolicy.isValidForCreation(List.filled(64, 'a').join()),
        isTrue,
      );
    });

    test('counts Unicode code points, not UTF-16 code units', () {
      const shortPassword = '🔒🔒🔒🔒🔒🔒🔒🔒🔒🔒🔒🔒🔒🔒';
      const validPassword = '🔒🔒🔒🔒🔒🔒🔒🔒🔒🔒🔒🔒🔒🔒🔒';

      expect(shortPassword.length, greaterThan(PasswordPolicy.minimumLength));
      expect(PasswordPolicy.isValidForCreation(shortPassword), isFalse);
      expect(PasswordPolicy.isValidForCreation(validPassword), isTrue);
    });
  });
}
