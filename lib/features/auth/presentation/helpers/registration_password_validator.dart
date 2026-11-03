import '../../../../l10n/app_localizations.dart';
import '../../domain/policies/password_policy.dart';

/// Adapts the Domain creation policy to localized Flutter form errors.
abstract final class RegistrationPasswordValidator {
  static String? validate(String? password, AppLocalizations l10n) {
    if (PasswordPolicy.isValidForCreation(password ?? '')) {
      return null;
    }

    return l10n.passwordMinLength;
  }
}
