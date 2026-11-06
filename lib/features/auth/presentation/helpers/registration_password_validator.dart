import '../../../../l10n/app_localizations.dart';
import '../../domain/policies/password_policy.dart';

/// Adapts the Domain creation policy to localized Flutter form errors.
abstract final class RegistrationPasswordValidator {
  static String? validate(String? password, AppLocalizations l10n) {
    return switch (PasswordPolicy.validateForCreation(password ?? '')) {
      PasswordCreationValidation.valid => null,
      PasswordCreationValidation.tooShort => l10n.passwordMinLength,
      PasswordCreationValidation.tooLong => l10n.passwordMaxLengthBytes,
    };
  }
}
