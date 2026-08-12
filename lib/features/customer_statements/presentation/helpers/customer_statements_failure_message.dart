import 'package:flutter/widgets.dart';

import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../../company/domain/failures/company_failure_codes.dart';
import '../../domain/failures/customer_statement_failure_codes.dart';
import '../localization/customer_statements_localizations.dart';

String customerStatementsFailureMessage(
  BuildContext context,
  Failure failure,
) {
  final strings = context.customerStatementsL10n;

  return switch (failure.code) {
    CustomerStatementFailureCodes.permissionView => strings.permissionFailure,
    CustomerStatementFailureCodes.validationCustomerIdRequired =>
      strings.customerRequiredFailure,
    CustomerStatementFailureCodes.validationDateRange =>
      strings.dateRangeFailure,
    CustomerStatementFailureCodes.customerNotFound =>
      strings.customerNotFoundFailure,
    CustomerStatementFailureCodes.conflictSourceInvalid =>
      strings.sourceInvalidFailure,
    CustomerStatementFailureCodes.conflictCurrencyMismatch =>
      strings.currencyMismatchFailure,
    CustomerStatementFailureCodes.conflictMovementInvalid =>
      strings.movementInvalidFailure,
    CompanyFailureCodes.conflictRegionalSettingsNotConfigured =>
      strings.regionalSettingsFailure,
    CompanyFailureCodes.notFound => strings.companyNotFoundFailure,
    _ => _safeFallback(context, failure, strings),
  };
}

String _safeFallback(
  BuildContext context,
  Failure failure,
  CustomerStatementsLocalizations strings,
) {
  if (failure is ServerFailure || failure is UnexpectedFailure) {
    return context.l10n.localizedErrorMessage(failure);
  }
  if (failure is PermissionFailure) return strings.permissionFailure;
  if (failure is NotFoundFailure) return strings.customerNotFoundFailure;
  if (failure is ConflictFailure) return strings.sourceInvalidFailure;
  if (failure is ValidationFailure) return strings.loadFailed;
  return strings.loadFailed;
}
