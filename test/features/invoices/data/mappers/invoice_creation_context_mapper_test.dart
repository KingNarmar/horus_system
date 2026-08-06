import 'package:horus_system/features/invoices/data/mappers/invoice_creation_context_mapper.dart';
import 'package:horus_system/features/invoices/data/models/invoice_creation_context_model.dart';
import 'package:horus_system/features/trips/domain/entities/trip_status.dart';
import 'package:test/test.dart';

void main() {
  group('InvoiceCreationContextModelMapper', () {
    test('maps trusted customer and billable trip context', () {
      final context = InvoiceCreationContextModel.fromMap(
        _contextMap(),
        companyId: 'company-1',
      ).toEntity();

      expect(context.customer.customerId, 'customer-1');
      expect(context.isCustomerActive, isTrue);
      expect(context.trips, hasLength(1));
      expect(context.trips.single.status, TripStatus.documentsReceived);
      expect(context.trips.single.freightAmount.minorUnits, 125050);
      expect(context.trips.single.freightAmount.currency.value, 'AED');
      expect(context.trips.single.isAlreadyInvoiced, isFalse);
    });

    test('rejects a trip from another company', () {
      final map = _contextMap();
      final trips = map['trips'] as List<Map<String, dynamic>>;
      trips.single['company_id'] = 'company-2';

      expect(
        () => InvoiceCreationContextModel.fromMap(
          map,
          companyId: 'company-1',
        ).toEntity(),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects unknown trip statuses instead of defaulting', () {
      final map = _contextMap();
      final trips = map['trips'] as List<Map<String, dynamic>>;
      trips.single['status'] = 'unknown';

      expect(
        () => InvoiceCreationContextModel.fromMap(
          map,
          companyId: 'company-1',
        ).toEntity(),
        throwsA(isA<FormatException>()),
      );
    });
  });
}

Map<String, dynamic> _contextMap() {
  return {
    'customer': <String, dynamic>{
      'customer_id': 'customer-1',
      'customer_name': 'Customer One',
      'customer_tax_registration_number': 'TRN-1',
      'customer_address': 'Address',
      'customer_city': 'Dubai',
      'customer_country': 'AE',
    },
    'is_customer_active': true,
    'trips': <Map<String, dynamic>>[
      {
        'id': 'trip-1',
        'company_id': 'company-1',
        'customer_id': 'customer-1',
        'status': 'documents_received',
        'freight_minor_units': 125050,
        'currency_code': 'AED',
        'is_already_invoiced': false,
        'loading_order_number': 'LO-1',
        'waybill_number': 'WB-1',
        'service_date': '2026-08-01',
        'quantity_tons': 25.5,
      },
    ],
  };
}
