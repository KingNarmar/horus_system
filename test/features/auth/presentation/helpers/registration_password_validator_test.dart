import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/features/auth/domain/policies/password_policy.dart';
import 'package:horus_system/features/auth/presentation/helpers/registration_password_validator.dart';
import 'package:horus_system/l10n/app_localizations_ar.dart';
import 'package:horus_system/l10n/app_localizations_en.dart';

void main() {
  test('EN/AR registration errors reflect both Domain password limits', () {
    final en = AppLocalizationsEn();
    final ar = AppLocalizationsAr();
    final minimum = PasswordPolicy.minimumLength.toString();
    final maximumBytes = PasswordPolicy.maximumUtf8Bytes.toString();

    expect(en.passwordMinLength, contains(minimum));
    expect(ar.passwordMinLength, contains(minimum));
    expect(en.passwordMaxLengthBytes, contains(maximumBytes));
    expect(ar.passwordMaxLengthBytes, contains(maximumBytes));

    for (final locale in [en, ar]) {
      expect(
        RegistrationPasswordValidator.validate('12345678901234', locale),
        locale.passwordMinLength,
      );
      expect(
        RegistrationPasswordValidator.validate(
          List.filled(19, '🔒').join(),
          locale,
        ),
        locale.passwordMaxLengthBytes,
      );
      expect(
        RegistrationPasswordValidator.validate('123456789012345', locale),
        isNull,
      );
      expect(
        RegistrationPasswordValidator.validate(
          List.filled(18, '🔒').join(),
          locale,
        ),
        isNull,
      );
    }
  });
}
