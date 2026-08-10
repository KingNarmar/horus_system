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
}
