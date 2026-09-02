import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure.dart';
import '../../domain/failures/company_failure_codes.dart';
import '../localization/company_timezone_localizations.dart';

String companyTimezoneFailureMessage(
  Failure failure,
  CompanyTimezoneLocalizations l10n,
) {
  if (failure is AuthFailure) return l10n.authFailure;

  return switch (failure.code) {
    CompanyFailureCodes.validationBusinessTimezoneRequired => l10n.required,
    CompanyFailureCodes.validationBusinessTimezoneInvalid => l10n.invalid,
    CompanyFailureCodes.permissionSettingsManagement => l10n.permissionFailure,
    CompanyFailureCodes.notFound => l10n.notFoundFailure,
    _ => l10n.genericFailure,
  };
}
