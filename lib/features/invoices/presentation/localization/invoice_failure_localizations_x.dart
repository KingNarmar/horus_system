import 'package:flutter/widgets.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/errors/failure_codes.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../../company/domain/failures/company_failure_codes.dart';
import '../../domain/failures/invoice_failure_codes.dart';
import 'invoices_localizations.dart';

extension InvoiceFailureLocalizationsX on BuildContext {
  String localizedInvoiceFailure(Failure failure) {
    final strings = invoicesL10n;
    return switch (failure.code) {
      FailureCodes.permissionInvoicesView => strings.permissionViewFailure,
      FailureCodes.permissionInvoicesManagement ||
      FailureCodes.permissionInvoicesIssue ||
      FailureCodes.permissionInvoicesCancel => strings.permissionManageFailure,
      FailureCodes.validationInvoiceCustomerRequired =>
        strings.customerRequiredFailure,
      FailureCodes.validationInvoiceTripsRequired => strings.tripsRequiredFailure,
      FailureCodes.validationInvoiceSingleTripRequired =>
        strings.singleTripRequiredFailure,
      FailureCodes.conflictInvoiceTripNotBillable =>
        strings.tripNotBillableFailure,
      FailureCodes.conflictInvoiceTripAlreadyInvoiced =>
        strings.tripAlreadyInvoicedFailure,
      FailureCodes.conflictInvoiceCustomerInactive =>
        strings.customerInactiveFailure,
      CompanyFailureCodes.conflictRegionalSettingsNotConfigured =>
        strings.regionalSettingsFailure,
      InvoiceFailureCodes.conflictSettingsNotConfigured =>
        strings.settingsFailure,
      _ => l10n.localizedErrorMessage(failure),
    };
  }
}
