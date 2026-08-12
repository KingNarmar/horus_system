import 'package:horus_system/features/customer_statements/data/mappers/customer_statement_mapper.dart';
import 'package:horus_system/features/customer_statements/data/models/customer_statement_source_model.dart';
import 'package:horus_system/features/customer_statements/domain/entities/customer_statement_movement_type.dart';
import 'package:test/test.dart';

void main() {
  test('maps RPC model into pure domain source', () {
    final model = CustomerStatementSourceModel(
      companyId: 'company-1',
      baseCurrencyCode: 'AED',
      baseCurrencyFractionDigits: 2,
      businessTimezone: 'Asia/Dubai',
      customerId: 'customer-1',
      customerName: 'Customer',
      customerIsActive: false,
      fromDate: DateTime(2026, 8, 10),
      toDate: DateTime(2026, 8, 10),
      openingInvoices: const [
        CustomerStatementOpeningAmountModel(
          currencyCode: 'AED',
          totalMinorUnits: 10000,
        ),
      ],
      openingPayments: const [],
      movements: [
        CustomerStatementMovementModel(
          sourceType: 'payment',
          sourceId: 'payment-1',
          businessDate: DateTime(2026, 8, 10),
          eventTimestamp: DateTime.utc(2026, 8, 10, 18),
          amountMinorUnits: 4000,
          currencyCode: 'AED',
          reference: 'REF-1',
          relatedInvoiceId: 'invoice-1',
        ),
      ],
    );

    final entity = model.toEntity();

    expect(entity.companyId, 'company-1');
    expect(entity.customerIsActive, isFalse);
    expect(entity.baseCurrency.value, 'AED');
    expect(entity.openingInvoiceAmounts.single.minorUnits, 10000);
    expect(entity.movements.single.type, CustomerStatementMovementType.payment);
  });

  test('rejects unknown movement type', () {
    final model = CustomerStatementSourceModel(
      companyId: 'company-1',
      baseCurrencyCode: 'AED',
      baseCurrencyFractionDigits: 2,
      businessTimezone: 'Asia/Dubai',
      customerId: 'customer-1',
      customerName: 'Customer',
      customerIsActive: true,
      fromDate: null,
      toDate: null,
      openingInvoices: const [],
      openingPayments: const [],
      movements: [
        CustomerStatementMovementModel(
          sourceType: 'credit_note',
          sourceId: 'source-1',
          businessDate: DateTime(2026, 8, 10),
          eventTimestamp: DateTime.utc(2026, 8, 10),
          amountMinorUnits: 1000,
          currencyCode: 'AED',
          reference: null,
          relatedInvoiceId: 'invoice-1',
        ),
      ],
    );

    expect(model.toEntity, throwsFormatException);
  });

  test('rejects invalid currency code', () {
    final model = CustomerStatementSourceModel(
      companyId: 'company-1',
      baseCurrencyCode: 'A',
      baseCurrencyFractionDigits: 2,
      businessTimezone: 'Asia/Dubai',
      customerId: 'customer-1',
      customerName: 'Customer',
      customerIsActive: true,
      fromDate: null,
      toDate: null,
      openingInvoices: const [],
      openingPayments: const [],
      movements: const [],
    );

    expect(model.toEntity, throwsFormatException);
  });
}
