import '../../../../core/domain/value_objects/currency_code.dart';
import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/errors/failure_codes.dart';
import '../../../trips/domain/entities/trip_status.dart';
import '../entities/billable_trip.dart';

abstract final class InvoiceTripEligibilityPolicy {
  static Failure? validate({
    required BillableTrip trip,
    required String companyId,
    required String customerId,
    required CurrencyCode currency,
  }) {
    if (trip.companyId != companyId) {
      return const ConflictFailure(
        code: FailureCodes.conflictInvoiceTripCompanyMismatch,
      );
    }

    if (trip.customerId != customerId) {
      return const ConflictFailure(
        code: FailureCodes.conflictInvoiceTripCustomerMismatch,
      );
    }

    if (trip.isAlreadyInvoiced) {
      return const ConflictFailure(
        code: FailureCodes.conflictInvoiceTripAlreadyInvoiced,
      );
    }

    if (trip.status != TripStatus.documentsReceived) {
      return const ConflictFailure(
        code: FailureCodes.conflictInvoiceTripNotBillable,
      );
    }

    if (trip.freightAmount.currency != currency) {
      return const ValidationFailure(
        code: FailureCodes.validationInvoiceCurrencyMismatch,
      );
    }

    if (!trip.freightAmount.isPositive) {
      return const ValidationFailure(
        code: FailureCodes.validationInvoiceLineAmountPositive,
      );
    }

    return null;
  }
}
