import 'package:flutter/widgets.dart';

import '../../../../core/errors/common_failures.dart';
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
      FailureCodes.permissionInvoicesCancel ||
      InvoiceFailureCodes.permissionSettingsManagement =>
        strings.permissionManageFailure,
      FailureCodes.validationInvoiceCustomerRequired =>
        strings.customerRequiredFailure,
      FailureCodes.validationInvoiceTripsRequired => strings.tripsRequiredFailure,
      FailureCodes.validationInvoiceSingleTripRequired ||
      FailureCodes.validationInvoiceGroupedTripsRequired =>
        strings.singleTripRequiredFailure,
      FailureCodes.conflictInvoiceTripNotBillable =>
        strings.tripNotBillableFailure,
      FailureCodes.conflictInvoiceTripAlreadyInvoiced =>
        strings.tripAlreadyInvoicedFailure,
      FailureCodes.conflictInvoiceCustomerInactive =>
        strings.customerInactiveFailure,
      FailureCodes.validationInvoiceIssueDateFuture =>
        strings.issueDateFutureFailure,
      FailureCodes.validationInvoiceDueDateBeforeIssue =>
        strings.dueDateBeforeIssueFailure,
      FailureCodes.validationInvoiceCancellationReasonRequired =>
        strings.cancellationReasonFailure,
      FailureCodes.conflictInvoiceStatusTransitionInvalid ||
      FailureCodes.conflictInvoiceIssuedImmutable => strings.invalidStatusFailure,
      FailureCodes.conflictInvoiceCustomerSnapshotChanged ||
      FailureCodes.conflictInvoiceTripSnapshotChanged ||
      FailureCodes.conflictInvoiceTotalsMismatch ||
      InvoiceFailureCodes.conflictSequenceExhausted =>
        strings.invoiceChangedFailure,
      CompanyFailureCodes.conflictRegionalSettingsNotConfigured =>
        strings.regionalSettingsFailure,
      InvoiceFailureCodes.conflictSettingsNotConfigured ||
      InvoiceFailureCodes.validationPrefixInvalid => strings.settingsFailure,
      InvoiceFailureCodes.notFound ||
      FailureCodes.validationInvoiceIdRequired => strings.invoiceNotFoundFailure,
      InvoiceFailureCodes.customerNotFound => strings.customerRequiredFailure,
      InvoiceFailureCodes.validationIssueDateRequired ||
      InvoiceFailureCodes.validationDueDateRequired => strings.dateRequired,
      _ => _safeInvoiceFallback(failure, strings),
    };
  }

  String _safeInvoiceFallback(
    Failure failure,
    InvoicesLocalizations strings,
  ) {
    if (failure is ServerFailure || failure is UnexpectedFailure) {
      return l10n.localizedErrorMessage(failure);
    }
    if (failure is PermissionFailure) return strings.permissionManageFailure;
    if (failure is NotFoundFailure) return strings.invoiceNotFoundFailure;
    if (failure is ConflictFailure) return strings.invoiceChangedFailure;
    if (failure is ValidationFailure) return strings.draftFailed;
    return strings.loadFailed;
  }
}
