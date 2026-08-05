import 'package:horus_system/core/domain/value_objects/currency_code.dart';
import 'package:horus_system/core/domain/value_objects/money.dart';
import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/invoices/domain/entities/billable_trip.dart';
import 'package:horus_system/features/invoices/domain/entities/invoice_creation_context.dart';
import 'package:horus_system/features/invoices/domain/entities/invoice_customer_snapshot.dart';
import 'package:horus_system/features/invoices/domain/entities/invoice_draft_data.dart';
import 'package:horus_system/features/invoices/domain/services/invoice_draft_factory.dart';
import 'package:horus_system/features/trips/domain/entities/trip_status.dart';
import 'package:test/test.dart';

void main() {
  const factory = InvoiceDraftFactory();
  final aed = CurrencyCode.tryParse('AED')!;

  InvoiceCreationContext context({
    bool customerActive = true,
    TripStatus status = TripStatus.documentsReceived,
    bool alreadyInvoiced = false,
    String tripCustomerId = 'customer-1',
  }) {
    return InvoiceCreationContext(
      customer: const InvoiceCustomerSnapshot(
        companyId: 'company-1',
        customerId: 'customer-1',
        name: 'Customer',
      ),
      isCustomerActive: customerActive,
      trips: [
        BillableTrip(
          id: 'trip-1',
          companyId: 'company-1',
          customerId: tripCustomerId,
          status: status,
          freightAmount: Money(minorUnits: 10000, currency: aed),
          isAlreadyInvoiced: alreadyInvoiced,
        ),
        BillableTrip(
          id: 'trip-2',
          companyId: 'company-1',
          customerId: tripCustomerId,
          status: status,
          freightAmount: Money(minorUnits: 5000, currency: aed),
          isAlreadyInvoiced: alreadyInvoiced,
        ),
      ],
    );
  }

  test('creates a grouped draft for eligible trips of one customer', () {
    final result = factory.create(
      companyId: 'company-1',
      customerId: 'customer-1',
      requestedTripIds: ['trip-1', 'trip-2'],
      context: context(),
      currencyCode: 'AED',
      discountMinorUnits: 1000,
      taxRateBasisPoints: 500,
      issueDate: DateTime.utc(2026, 8, 5),
      dueDate: DateTime.utc(2026, 9, 4),
    );

    expect(result, isA<Success<InvoiceDraftData>>());
    final draft = (result as Success<InvoiceDraftData>).data;
    expect(draft.lines.map((line) => line.tripId), ['trip-1', 'trip-2']);
    expect(draft.totals.grandTotal.minorUnits, 14700);
  });

  test('rejects duplicate trip ids', () {
    final result = factory.create(
      companyId: 'company-1',
      customerId: 'customer-1',
      requestedTripIds: ['trip-1', 'trip-1'],
      context: context(),
      currencyCode: 'AED',
      discountMinorUnits: 0,
      taxRateBasisPoints: 0,
    );

    expect(
      result.failureOrNull?.code,
      FailureCodes.validationInvoiceDuplicateTrip,
    );
  });

  test('rejects non-billable trip statuses', () {
    final result = factory.create(
      companyId: 'company-1',
      customerId: 'customer-1',
      requestedTripIds: ['trip-1'],
      context: context(status: TripStatus.delivered),
      currencyCode: 'AED',
      discountMinorUnits: 0,
      taxRateBasisPoints: 0,
    );

    expect(
      result.failureOrNull?.code,
      FailureCodes.conflictInvoiceTripNotBillable,
    );
  });

  test('rejects an already invoiced trip', () {
    final result = factory.create(
      companyId: 'company-1',
      customerId: 'customer-1',
      requestedTripIds: ['trip-1'],
      context: context(alreadyInvoiced: true),
      currencyCode: 'AED',
      discountMinorUnits: 0,
      taxRateBasisPoints: 0,
    );

    expect(
      result.failureOrNull?.code,
      FailureCodes.conflictInvoiceTripAlreadyInvoiced,
    );
  });

  test('rejects trips belonging to another customer', () {
    final result = factory.create(
      companyId: 'company-1',
      customerId: 'customer-1',
      requestedTripIds: ['trip-1'],
      context: context(tripCustomerId: 'customer-2'),
      currencyCode: 'AED',
      discountMinorUnits: 0,
      taxRateBasisPoints: 0,
    );

    expect(
      result.failureOrNull?.code,
      FailureCodes.conflictInvoiceTripCustomerMismatch,
    );
  });

  test('rejects due date before issue date', () {
    final result = factory.create(
      companyId: 'company-1',
      customerId: 'customer-1',
      requestedTripIds: ['trip-1'],
      context: context(),
      currencyCode: 'AED',
      discountMinorUnits: 0,
      taxRateBasisPoints: 0,
      issueDate: DateTime.utc(2026, 8, 5),
      dueDate: DateTime.utc(2026, 8, 4),
    );

    expect(
      result.failureOrNull?.code,
      FailureCodes.validationInvoiceDueDateBeforeIssue,
    );
  });
}
