import 'package:flutter/widgets.dart';

import '../../../../core/errors/failure.dart';
import '../../../company/domain/failures/company_failure_codes.dart';
import '../../domain/failures/reports_failure_codes.dart';
import '../localization/reports_localizations.dart';

String reportsFailureMessage(BuildContext context, Failure failure) {
  final strings = context.reportsL10n;
  return switch (failure.code) {
    ReportsFailureCodes.permissionOperationalView ||
    ReportsFailureCodes.permissionFinancialView ||
    ReportsFailureCodes.permissionOpenInvoicesView => strings.permissionFailure,
    ReportsFailureCodes.validationDateRange => strings.invalidDateRangeFailure,
    CompanyFailureCodes.conflictRegionalSettingsNotConfigured =>
      strings.regionalSettingsFailure,
    CompanyFailureCodes.notFound => strings.companyNotFoundFailure,
    ReportsFailureCodes.conflictSourceInvalid => strings.sourceInvalidFailure,
    ReportsFailureCodes.conflictCurrencyMismatch =>
      strings.currencyMismatchFailure,
    ReportsFailureCodes.conflictFinancialDataInvalid =>
      strings.financialDataInvalidFailure,
    ReportsFailureCodes.conflictInvoiceBalanceInvalid =>
      strings.invoiceBalanceInvalidFailure,
    _ => strings.loadFailed,
  };
}
