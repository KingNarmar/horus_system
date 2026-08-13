import 'package:flutter/widgets.dart';

import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../../company/domain/failures/company_failure_codes.dart';
import '../../domain/failures/dashboard_failure_codes.dart';
import '../localization/dashboard_localizations.dart';

String dashboardFailureMessage(BuildContext context, Failure failure) {
  final strings = context.dashboardL10n;

  return switch (failure.code) {
    DashboardFailureCodes.permissionView => strings.permissionFailure,
    DashboardFailureCodes.conflictSourceInvalid => strings.sourceInvalidFailure,
    DashboardFailureCodes.conflictCurrencyMismatch =>
      strings.currencyMismatchFailure,
    DashboardFailureCodes.conflictFinancialDataInvalid =>
      strings.financialDataInvalidFailure,
    CompanyFailureCodes.conflictRegionalSettingsNotConfigured =>
      strings.regionalSettingsFailure,
    CompanyFailureCodes.notFound => strings.companyNotFoundFailure,
    _ => _safeFallback(context, failure, strings),
  };
}

String _safeFallback(
  BuildContext context,
  Failure failure,
  DashboardLocalizations strings,
) {
  if (failure is ServerFailure || failure is UnexpectedFailure) {
    return context.l10n.localizedErrorMessage(failure);
  }
  if (failure is PermissionFailure) return strings.permissionFailure;
  if (failure is NotFoundFailure) return strings.companyNotFoundFailure;
  if (failure is ConflictFailure) return strings.sourceInvalidFailure;
  return strings.loadFailed;
}
