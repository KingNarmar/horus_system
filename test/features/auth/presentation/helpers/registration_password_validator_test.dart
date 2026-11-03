import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/features/auth/presentation/helpers/registration_password_validator.dart';
import 'package:horus_system/l10n/app_localizations_ar.dart';
import 'package:horus_system/l10n/app_localizations_en.dart';

void main() {
  test('English and Arabic use the same Domain policy boundary', () {
    final en = AppLocalizationsEn();
    final ar = AppLocalizationsAr();

    expect(
      RegistrationPasswordValidator.validate('12345678901234', en),
      en.passwordMinLength,
    );
    expect(
      RegistrationPasswordValidator.validate('12345678901234', ar),
      ar.passwordMinLength,
    );
    expect(
      RegistrationPasswordValidator.validate('123456789012345', en),
      isNull,
    );
    expect(
      RegistrationPasswordValidator.validate('123456789012345', ar),
      isNull,
    );
  });
}
