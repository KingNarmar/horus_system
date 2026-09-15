import '../../../../core/errors/failure.dart';
import '../../domain/failures/company_failure_codes.dart';
import '../localization/company_financial_settings_localizations.dart';

String companyFinancialSettingsFailureMessage(
  Failure failure,
  CompanyFinancialSettingsLocalizations l10n,
) {
  return switch (failure.code) {
    CompanyFailureCodes.validationBaseCurrencyInvalid => l10n.invalidCurrency,
    CompanyFailureCodes.validationBaseCurrencyFractionDigitsInvalid =>
      l10n.invalidFractionDigits,
    CompanyFailureCodes.conflictBaseCurrencyLocked => l10n.lockedFailure,
    CompanyFailureCodes.conflictBaseCurrencyHistoryMismatch =>
      l10n.historyMismatchFailure,
    CompanyFailureCodes.permissionSettingsManagement => l10n.permissionFailure,
    CompanyFailureCodes.notFound => l10n.notFoundFailure,
    CompanyFailureCodes.authRequired => l10n.authFailure,
    _ => l10n.genericFailure,
  };
}
