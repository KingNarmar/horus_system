import '../../../../core/domain/value_objects/currency_code.dart';
import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure_codes.dart';
import '../../../../core/utils/result.dart';
import '../entities/invoice_creation_context.dart';
import '../entities/invoice_draft_data.dart';
import '../entities/invoice_totals.dart';
import '../entities/invoice_trip_line.dart';
import '../policies/invoice_trip_eligibility_policy.dart';
import '../value_objects/invoice_date.dart';
import 'invoice_totals_calculator.dart';

final class InvoiceDraftFactory {
  final InvoiceTotalsCalculator _totalsCalculator;

  const InvoiceDraftFactory({
    InvoiceTotalsCalculator totalsCalculator = const InvoiceTotalsCalculator(),
  }) : _totalsCalculator = totalsCalculator;

  Result<InvoiceDraftData> create({
    required String companyId,
    required String customerId,
    required List<String> requestedTripIds,
    required InvoiceCreationContext context,
    required String currencyCode,
    required int discountMinorUnits,
    required int taxRateBasisPoints,
    DateTime? issueDate,
    DateTime? dueDate,
    String? notes,
  }) {
    if (requestedTripIds.isEmpty) {
      return const FailureResult<InvoiceDraftData>(
        ValidationFailure(code: FailureCodes.validationInvoiceTripsRequired),
      );
    }

    if (requestedTripIds.toSet().length != requestedTripIds.length) {
      return const FailureResult<InvoiceDraftData>(
        ValidationFailure(code: FailureCodes.validationInvoiceDuplicateTrip),
      );
    }

    final currency = CurrencyCode.tryParse(currencyCode);
    if (currency == null) {
      return const FailureResult<InvoiceDraftData>(
        ValidationFailure(code: FailureCodes.validationInvoiceCurrencyInvalid),
      );
    }

    final customer = context.customer;
    if (customer.companyId != companyId) {
      return const FailureResult<InvoiceDraftData>(
        ConflictFailure(
          code: FailureCodes.conflictInvoiceCustomerCompanyMismatch,
        ),
      );
    }

    if (customer.customerId != customerId) {
      return const FailureResult<InvoiceDraftData>(
        ConflictFailure(code: FailureCodes.conflictInvoiceCustomerMismatch),
      );
    }

    if (!context.isCustomerActive) {
      return const FailureResult<InvoiceDraftData>(
        ConflictFailure(code: FailureCodes.conflictInvoiceCustomerInactive),
      );
    }

    final tripsById = {for (final trip in context.trips) trip.id: trip};
    final selectedTrips = <InvoiceTripLine>[];

    for (final tripId in requestedTripIds) {
      final trip = tripsById[tripId];
      if (trip == null) {
        return const FailureResult<InvoiceDraftData>(
          NotFoundFailure(code: FailureCodes.invoiceTripNotFound),
        );
      }

      final eligibilityFailure = InvoiceTripEligibilityPolicy.validate(
        trip: trip,
        companyId: companyId,
        customerId: customerId,
        currency: currency,
      );
      if (eligibilityFailure != null) {
        return FailureResult<InvoiceDraftData>(eligibilityFailure);
      }

      selectedTrips.add(InvoiceTripLine.fromBillableTrip(trip));
    }

    final normalizedIssueDate = issueDate == null
        ? null
        : InvoiceDate.fromDateTime(issueDate);
    final normalizedDueDate = dueDate == null
        ? null
        : InvoiceDate.fromDateTime(dueDate);

    if (normalizedIssueDate != null &&
        normalizedDueDate != null &&
        normalizedDueDate.isBefore(normalizedIssueDate)) {
      return const FailureResult<InvoiceDraftData>(
        ValidationFailure(
          code: FailureCodes.validationInvoiceDueDateBeforeIssue,
        ),
      );
    }

    final totalsResult = _totalsCalculator.calculate(
      lineAmounts: selectedTrips.map((line) => line.amount).toList(),
      currency: currency,
      discountMinorUnits: discountMinorUnits,
      taxRateBasisPoints: taxRateBasisPoints,
    );
    if (totalsResult is FailureResult<InvoiceTotals>) {
      return FailureResult<InvoiceDraftData>(totalsResult.failure);
    }

    return Success<InvoiceDraftData>(
      InvoiceDraftData(
        companyId: companyId,
        customer: customer,
        currency: currency,
        lines: selectedTrips,
        totals: (totalsResult as Success<InvoiceTotals>).data,
        issueDate: normalizedIssueDate,
        dueDate: normalizedDueDate,
        notes: _optional(notes),
      ),
    );
  }

  String? _optional(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) return null;
    return normalized;
  }
}
