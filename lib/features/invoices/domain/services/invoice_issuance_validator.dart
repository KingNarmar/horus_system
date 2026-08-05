import '../../../../core/domain/value_objects/money.dart';
import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/errors/failure_codes.dart';
import '../../../../core/utils/result.dart';
import '../entities/invoice.dart';
import '../entities/invoice_creation_context.dart';
import '../entities/invoice_totals.dart';
import '../entities/invoice_trip_line.dart';
import '../policies/invoice_trip_eligibility_policy.dart';
import 'invoice_totals_calculator.dart';

final class InvoiceIssuanceValidator {
  final InvoiceTotalsCalculator _totalsCalculator;

  const InvoiceIssuanceValidator({
    InvoiceTotalsCalculator totalsCalculator = const InvoiceTotalsCalculator(),
  }) : _totalsCalculator = totalsCalculator;

  Failure? validate({
    required Invoice invoice,
    required InvoiceCreationContext context,
  }) {
    if (invoice.lines.isEmpty) {
      return const ValidationFailure(
        code: FailureCodes.validationInvoiceTripsRequired,
      );
    }

    final tripIds = invoice.lines.map((line) => line.tripId).toList();
    if (tripIds.toSet().length != tripIds.length) {
      return const ValidationFailure(
        code: FailureCodes.validationInvoiceDuplicateTrip,
      );
    }

    if (context.customer.companyId != invoice.companyId) {
      return const ConflictFailure(
        code: FailureCodes.conflictInvoiceCustomerCompanyMismatch,
      );
    }

    if (context.customer.customerId != invoice.customer.customerId) {
      return const ConflictFailure(
        code: FailureCodes.conflictInvoiceCustomerMismatch,
      );
    }

    if (!context.isCustomerActive) {
      return const ConflictFailure(
        code: FailureCodes.conflictInvoiceCustomerInactive,
      );
    }

    if (context.customer != invoice.customer) {
      return const ConflictFailure(
        code: FailureCodes.conflictInvoiceCustomerSnapshotChanged,
      );
    }

    final tripsById = {for (final trip in context.trips) trip.id: trip};
    final currentLineAmounts = <Money>[];

    for (final line in invoice.lines) {
      final trip = tripsById[line.tripId];
      if (trip == null) {
        return const NotFoundFailure(code: FailureCodes.invoiceTripNotFound);
      }

      final failure = InvoiceTripEligibilityPolicy.validate(
        trip: trip,
        companyId: invoice.companyId,
        customerId: invoice.customer.customerId,
        currency: invoice.currency,
      );
      if (failure != null) return failure;

      final currentLine = InvoiceTripLine.fromBillableTrip(trip);
      if (line != currentLine) {
        return const ConflictFailure(
          code: FailureCodes.conflictInvoiceTripSnapshotChanged,
        );
      }

      currentLineAmounts.add(currentLine.amount);
    }

    final totalsResult = _totalsCalculator.calculate(
      lineAmounts: currentLineAmounts,
      currency: invoice.currency,
      discountMinorUnits: invoice.totals.discount.minorUnits,
      taxRateBasisPoints: invoice.totals.taxRate.basisPoints,
    );
    if (totalsResult is FailureResult<InvoiceTotals>) {
      return totalsResult.failure;
    }

    final currentTotals = (totalsResult as Success<InvoiceTotals>).data;
    if (currentTotals != invoice.totals) {
      return const ConflictFailure(
        code: FailureCodes.conflictInvoiceTotalsMismatch,
      );
    }

    return null;
  }
}
