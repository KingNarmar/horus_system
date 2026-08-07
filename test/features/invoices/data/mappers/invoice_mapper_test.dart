import 'package:horus_system/features/invoices/data/mappers/invoice_mapper.dart';
import 'package:horus_system/features/invoices/data/models/invoice_customer_snapshot_model.dart';
import 'package:horus_system/features/invoices/data/models/invoice_model.dart';
import 'package:horus_system/features/invoices/domain/entities/invoice_status.dart';
import 'package:test/test.dart';

void main() {
  group('InvoiceModelMapper', () {
    test('maps and orders a persisted invoice aggregate', () {
      final invoice = InvoiceModel.fromMap(_invoiceMap()).toEntity();

      expect(invoice.id, 'invoice-1');
      expect(invoice.companyId, 'company-1');
      expect(invoice.customer.customerId, 'customer-1');
      expect(invoice.status, InvoiceStatus.issued);
      expect(invoice.number?.value, 'INV-2026-000001');
      expect(invoice.currency.value, 'AED');
      expect(invoice.lines, hasLength(2));
      expect(invoice.lines.first.tripId, 'trip-1');
      expect(invoice.lines.first.tripNumber, 'TRIP-2026-000001');
      expect(invoice.lines.first.loadingLocation, 'Dubai');
      expect(invoice.lines.first.unloadingLocation, 'Abu Dhabi');
      expect(invoice.lines.first.amount.minorUnits, 6000);
      expect(invoice.lines.last.tripId, 'trip-2');
      expect(invoice.lines.last.amount.minorUnits, 4000);
      expect(invoice.totals.subtotal.minorUnits, 10000);
      expect(invoice.totals.discount.minorUnits, 500);
      expect(invoice.totals.taxableAmount.minorUnits, 9500);
      expect(invoice.totals.taxRate.basisPoints, 500);
      expect(invoice.totals.taxAmount.minorUnits, 475);
      expect(invoice.totals.grandTotal.minorUnits, 9975);
      expect(invoice.issueDate?.value, DateTime.utc(2026, 8, 5));
      expect(invoice.dueDate?.value, DateTime.utc(2026, 9, 4));
    });

    test('rejects a customer snapshot from another tenant', () {
      final persisted = InvoiceModel.fromMap(_invoiceMap());
      final mismatched = InvoiceModel(
        id: persisted.id,
        companyId: persisted.companyId,
        customer: InvoiceCustomerSnapshotModel(
          companyId: 'company-2',
          customerId: persisted.customer.customerId,
          name: persisted.customer.name,
          taxRegistrationNumber: persisted.customer.taxRegistrationNumber,
          address: persisted.customer.address,
          city: persisted.customer.city,
          country: persisted.customer.country,
        ),
        status: persisted.status,
        invoiceNumber: persisted.invoiceNumber,
        currencyCode: persisted.currencyCode,
        lines: persisted.lines,
        totals: persisted.totals,
        issueDate: persisted.issueDate,
        dueDate: persisted.dueDate,
        notes: persisted.notes,
        cancellationReason: persisted.cancellationReason,
        createdAt: persisted.createdAt,
        updatedAt: persisted.updatedAt,
      );

      expect(mismatched.toEntity, throwsA(isA<FormatException>()));
    });

    test('rejects line currency that differs from the invoice', () {
      final map = _invoiceMap();
      final lines = map['invoice_lines'] as List<Map<String, dynamic>>;
      lines.first['currency_code'] = 'USD';

      expect(
        () => InvoiceModel.fromMap(map).toEntity(),
        throwsA(isA<FormatException>()),
      );
    });
  });
}

Map<String, dynamic> _invoiceMap() {
  return {
    'id': 'invoice-1',
    'company_id': 'company-1',
    'customer_id': 'customer-1',
    'status': 'issued',
    'invoice_number': 'INV-2026-000001',
    'currency_code': 'AED',
    'customer_name': 'Customer One',
    'customer_tax_registration_number': 'TRN-1',
    'customer_address': 'Address',
    'customer_city': 'Dubai',
    'customer_country': 'AE',
    'subtotal_minor_units': 10000,
    'discount_minor_units': 500,
    'taxable_minor_units': 9500,
    'tax_rate_basis_points': 500,
    'tax_minor_units': 475,
    'total_minor_units': 9975,
    'issue_date': '2026-08-05',
    'due_date': '2026-09-04',
    'notes': 'Invoice note',
    'cancellation_reason': null,
    'created_at': '2026-08-05T10:00:00Z',
    'updated_at': '2026-08-05T11:00:00Z',
    'invoice_lines': <Map<String, dynamic>>[
      {
        'line_position': 2,
        'trip_id': 'trip-2',
        'trip_number': 'TRIP-2026-000002',
        'loading_location': 'Sharjah',
        'unloading_location': 'Dubai',
        'loading_order_number': 'LO-2',
        'waybill_number': 'WB-2',
        'service_date': '2026-08-02',
        'quantity_tons': 10,
        'amount_minor_units': 4000,
        'currency_code': 'AED',
      },
      {
        'line_position': 1,
        'trip_id': 'trip-1',
        'trip_number': 'TRIP-2026-000001',
        'loading_location': 'Dubai',
        'unloading_location': 'Abu Dhabi',
        'loading_order_number': 'LO-1',
        'waybill_number': 'WB-1',
        'service_date': '2026-08-01',
        'quantity_tons': 20,
        'amount_minor_units': 6000,
        'currency_code': 'AED',
      },
    ],
  };
}
