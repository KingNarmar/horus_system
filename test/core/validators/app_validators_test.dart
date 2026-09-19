import 'package:horus_system/core/validators/app_validators.dart';
import 'package:test/test.dart';

void main() {
  group('AppValidators.hasRequiredText', () {
    test('rejects null, empty, and whitespace-only values', () {
      expect(AppValidators.hasRequiredText(null), isFalse);
      expect(AppValidators.hasRequiredText(''), isFalse);
      expect(AppValidators.hasRequiredText('   '), isFalse);
    });

    test('accepts text after trimming', () {
      expect(AppValidators.hasRequiredText('Cash'), isTrue);
      expect(AppValidators.hasRequiredText('  Bank transfer  '), isTrue);
    });
  });

  group('AppValidators email validation', () {
    test('accepts practical valid email formats after trimming', () {
      expect(AppValidators.hasValidEmail('user@example.com'), isTrue);
      expect(
        AppValidators.hasValidEmail('  user.name+tag@example.co.uk  '),
        isTrue,
      );
    });

    test('rejects malformed email values', () {
      expect(AppValidators.hasValidEmail(null), isFalse);
      expect(AppValidators.hasValidEmail(''), isFalse);
      expect(AppValidators.hasValidEmail('user@'), isFalse);
      expect(AppValidators.hasValidEmail('@example.com'), isFalse);
      expect(AppValidators.hasValidEmail('user@example'), isFalse);
      expect(AppValidators.hasValidEmail('user example@example.com'), isFalse);
    });

    test(
      'optional email accepts missing values but rejects malformed text',
      () {
        expect(AppValidators.hasValidOptionalEmail(null), isTrue);
        expect(AppValidators.hasValidOptionalEmail('   '), isTrue);
        expect(AppValidators.hasValidOptionalEmail('user@example.com'), isTrue);
        expect(AppValidators.hasValidOptionalEmail('invalid-email'), isFalse);
      },
    );
  });
}
