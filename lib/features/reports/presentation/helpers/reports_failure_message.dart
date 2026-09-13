import 'package:flutter/widgets.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/localization/business_timezone_localizations.dart';
import '../../../../core/localization/financial_readiness_localizations.dart';
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
    CompanyFailureCodes.conflictFinancialSettingsNotConfigured =>
      context.financialReadinessL10n.configurationRequired,
    CompanyFailureCodes.conflictBusinessTimezoneNotConfigured ||
    CompanyFailureCodes.conflictRegionalSettingsNotConfigured =>
      context.businessTimezoneL10n.configurationRequired,
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
