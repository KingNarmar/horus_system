import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/errors/failure_codes.dart';
import '../../../company/domain/failures/company_failure_codes.dart';
import '../../domain/failures/invoice_failure_codes.dart';
import '../constants/invoices_rpc_error_codes.dart';

abstract final class InvoicesFailureMapper {
  static Failure fromPostgrest(
    PostgrestException error, {
    required String permissionCode,
  }) {
    return switch (error.code) {
      InvoicesRpcErrorCodes.noRowsReturned ||
      InvoicesRpcErrorCodes.invoiceNotFound => const NotFoundFailure(
        code: InvoiceFailureCodes.notFound,
      ),
      InvoicesRpcErrorCodes.permissionDenied => PermissionFailure(
        code: permissionCode,
      ),
      InvoicesRpcErrorCodes.regionalSettingsNotConfigured =>
        const ConflictFailure(
          code: CompanyFailureCodes.conflictRegionalSettingsNotConfigured,
        ),
      InvoicesRpcErrorCodes.settingsNotConfigured => const ConflictFailure(
        code: InvoiceFailureCodes.conflictSettingsNotConfigured,
      ),
      InvoicesRpcErrorCodes.customerNotFound => const NotFoundFailure(
        code: InvoiceFailureCodes.customerNotFound,
      ),
      InvoicesRpcErrorCodes.customerInactive => const ConflictFailure(
        code: FailureCodes.conflictInvoiceCustomerInactive,
      ),
      InvoicesRpcErrorCodes.tripNotFound => const NotFoundFailure(
        code: FailureCodes.invoiceTripNotFound,
      ),
      InvoicesRpcErrorCodes.tripNotBillable => const ConflictFailure(
        code: FailureCodes.conflictInvoiceTripNotBillable,
      ),
      InvoicesRpcErrorCodes.tripAlreadyInvoiced => const ConflictFailure(
        code: FailureCodes.conflictInvoiceTripAlreadyInvoiced,
      ),
      InvoicesRpcErrorCodes.invalidStatusTransition => const ConflictFailure(
        code: FailureCodes.conflictInvoiceStatusTransitionInvalid,
      ),
      InvoicesRpcErrorCodes.totalsChanged => const ConflictFailure(
        code: FailureCodes.conflictInvoiceTotalsMismatch,
      ),
      InvoicesRpcErrorCodes.freightPrecisionInvalid => const ValidationFailure(
        code: InvoiceFailureCodes.validationFreightPrecisionInvalid,
      ),
      InvoicesRpcErrorCodes.dueDateBeforeIssue => const ValidationFailure(
        code: FailureCodes.validationInvoiceDueDateBeforeIssue,
      ),
      InvoicesRpcErrorCodes.cancellationReasonRequired =>
        const ValidationFailure(
          code: FailureCodes.validationInvoiceCancellationReasonRequired,
        ),
      InvoicesRpcErrorCodes.linesRequired => const ValidationFailure(
        code: FailureCodes.validationInvoiceTripsRequired,
      ),
      InvoicesRpcErrorCodes.currencyMismatch => const ValidationFailure(
        code: FailureCodes.validationInvoiceCurrencyMismatch,
      ),
      InvoicesRpcErrorCodes.discountNegative => const ValidationFailure(
        code: FailureCodes.validationInvoiceDiscountNegative,
      ),
      InvoicesRpcErrorCodes.discountExceedsSubtotal => const ValidationFailure(
        code: FailureCodes.validationInvoiceDiscountExceedsSubtotal,
      ),
      InvoicesRpcErrorCodes.taxRateOutOfRange => const ValidationFailure(
        code: FailureCodes.validationInvoiceTaxRateOutOfRange,
      ),
      InvoicesRpcErrorCodes.totalNotPositive => const ValidationFailure(
        code: FailureCodes.validationInvoiceTotalPositive,
      ),
      InvoicesRpcErrorCodes.issueDateFuture => const ValidationFailure(
        code: FailureCodes.validationInvoiceIssueDateFuture,
      ),
      InvoicesRpcErrorCodes.duplicateTrips => const ValidationFailure(
        code: FailureCodes.validationInvoiceDuplicateTrip,
      ),
      InvoicesRpcErrorCodes.customerMismatch => const ConflictFailure(
        code: FailureCodes.conflictInvoiceCustomerMismatch,
      ),
      InvoicesRpcErrorCodes.companyNotFound => const NotFoundFailure(
        code: CompanyFailureCodes.notFound,
      ),
      InvoicesRpcErrorCodes.prefixInvalid => const ValidationFailure(
        code: InvoiceFailureCodes.validationPrefixInvalid,
      ),
      InvoicesRpcErrorCodes.issueDateRequired => const ValidationFailure(
        code: InvoiceFailureCodes.validationIssueDateRequired,
      ),
      InvoicesRpcErrorCodes.dueDateRequired => const ValidationFailure(
        code: InvoiceFailureCodes.validationDueDateRequired,
      ),
      InvoicesRpcErrorCodes.customerSnapshotChanged => const ConflictFailure(
        code: FailureCodes.conflictInvoiceCustomerSnapshotChanged,
      ),
      InvoicesRpcErrorCodes.tripSnapshotChanged => const ConflictFailure(
        code: FailureCodes.conflictInvoiceTripSnapshotChanged,
      ),
      InvoicesRpcErrorCodes.sequenceExhausted => const ConflictFailure(
        code: InvoiceFailureCodes.conflictSequenceExhausted,
      ),
      InvoicesRpcErrorCodes.hasPayments => const ConflictFailure(
        code: InvoiceFailureCodes.conflictHasPayments,
      ),
      _ => const ServerFailure(code: FailureCodes.serverError),
    };
  }
}
