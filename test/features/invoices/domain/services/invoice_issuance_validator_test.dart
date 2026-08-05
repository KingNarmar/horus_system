import 'package:horus_system/core/domain/value_objects/currency_code.dart';
import 'package:horus_system/core/domain/value_objects/money.dart';
import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/features/invoices/domain/entities/billable_trip.dart';
import 'package:horus_system/features/invoices/domain/entities/invoice.dart';
import 'package:horus_system/features/invoices/domain/entities/invoice_creation_context.dart';
import 'package:horus_system/features/invoices/domain/entities/invoice_customer_snapshot.dart';
import 'package:horus_system/features/invoices/domain/entities/invoice_status.dart';
import 'package:horus_system/features/invoices/domain/entities/invoice_totals.dart';
import 'package:horus_system/features/invoices/domain/entities/invoice_trip_line.dart';
import 'package:horus_system/features/invoices/domain/services/invoice_issuance_validator.dart';
import 'package:horus_system/features/invoices/domain/value_objects/tax_rate.dart';
import 'package:horus_system/features/trips/domain/entities/trip_status.dart';
import 'package:test/test.dart';

void main() {
  const validator = InvoiceIssuanceValidator();
  final currency = CurrencyCode.tryParse('AED')!;

  Invoice invoice({
    InvoiceCustomerSnapshot? customer,
    List<InvoiceTripLine>? lines,
    InvoiceTotals? totals,
  }) {
    final amount = Money(minorUnits: 10000, currency: currency);
    final zero = Money(minorUnits: 0, currency: currency);
    return Invoice(
      id: 'invoice-1',
      companyId: 'company-1',
      customer:
          customer ??
          const InvoiceCustomerSnapshot(
            companyId: 'company-1',
            customerId: 'customer-1',
            name: 'Customer',
          ),
      status: InvoiceStatus.draft,
      currency: currency,
      lines: lines ?? [InvoiceTripLine(tripId: 'trip-1', amount: amount)],
      totals:
          totals ??
          InvoiceTotals(
            subtotal: amount,
            discount: zero,
            taxableAmount: amount,
            taxRate: TaxRate.tryCreate(0)!,
            taxAmount: zero,
            grandTotal: amount,
          ),
      createdAt: DateTime.utc(2026, 8, 5),
      updatedAt: DateTime.utc(2026, 8, 5),
    );
  }

  InvoiceCreationContext context({
    InvoiceCustomerSnapshot? customer,
    TripStatus status = TripStatus.documentsReceived,
    bool customerActive = true,
    bool alreadyInvoiced = false,
    int freightMinorUnits = 10000,
    String? waybillNumber,
  }) {
    return InvoiceCreationContext(
      customer:
          customer ??
          const InvoiceCustomerSnapshot(
            companyId: 'company-1',
            customerId: 'customer-1',
            name: 'Customer',
          ),
      isCustomerActive: customerActive,
      trips: [
        BillableTrip(
          id: 'trip-1',
          companyId: 'company-1',
          customerId: 'customer-1',
          status: status,
          freightAmount: Money(
            minorUnits: freightMinorUnits,
            currency: currency,
          ),
          isAlreadyInvoiced: alreadyInvoiced,
          waybillNumber: waybillNumber,
        ),
      ],
    );
  }

  test('accepts a still-current billable draft at issuance time', () {
    expect(validator.validate(invoice: invoice(), context: context()), isNull);
  });

  test('rejects a trip cancelled after draft creation', () {
    final failure = validator.validate(
      invoice: invoice(),
      context: context(status: TripStatus.cancelled),
    );

    expect(failure?.code, FailureCodes.conflictInvoiceTripNotBillable);
  });

  test('rejects a trip invoiced by another invoice before issuance', () {
    final failure = validator.validate(
      invoice: invoice(),
      context: context(alreadyInvoiced: true),
    );

    expect(failure?.code, FailureCodes.conflictInvoiceTripAlreadyInvoiced);
  });

  test('rejects duplicate trip lines in the persisted draft', () {
    final amount = Money(minorUnits: 10000, currency: currency);
    final failure = validator.validate(
      invoice: invoice(
        lines: [
          InvoiceTripLine(tripId: 'trip-1', amount: amount),
          InvoiceTripLine(tripId: 'trip-1', amount: amount),
        ],
      ),
      context: context(),
    );

    expect(failure?.code, FailureCodes.validationInvoiceDuplicateTrip);
  });

  test('rejects a customer snapshot changed after draft creation', () {
    final failure = validator.validate(
      invoice: invoice(),
      context: context(
        customer: const InvoiceCustomerSnapshot(
          companyId: 'company-1',
          customerId: 'customer-1',
          name: 'Updated Customer Name',
        ),
      ),
    );

    expect(failure?.code, FailureCodes.conflictInvoiceCustomerSnapshotChanged);
  });

  test('rejects a trip snapshot changed after draft creation', () {
    final failure = validator.validate(
      invoice: invoice(),
      context: context(freightMinorUnits: 11000),
    );

    expect(failure?.code, FailureCodes.conflictInvoiceTripSnapshotChanged);
  });

  test('rejects persisted totals that do not match current lines', () {
    final amount = Money(minorUnits: 10000, currency: currency);
    final zero = Money(minorUnits: 0, currency: currency);
    final staleTotal = Money(minorUnits: 9000, currency: currency);
    final failure = validator.validate(
      invoice: invoice(
        totals: InvoiceTotals(
          subtotal: amount,
          discount: zero,
          taxableAmount: amount,
          taxRate: TaxRate.tryCreate(0)!,
          taxAmount: zero,
          grandTotal: staleTotal,
        ),
      ),
      context: context(),
    );

    expect(failure?.code, FailureCodes.conflictInvoiceTotalsMismatch);
  });
}
