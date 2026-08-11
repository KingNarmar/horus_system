import 'package:horus_system/features/payments/data/mappers/payment_mapper.dart';
import 'package:horus_system/features/payments/data/models/payment_model.dart';
import 'package:test/test.dart';

void main() {
  test('maps persisted minor units and currency to Money exactly', () {
    final entity = PaymentModel(
      id: 'payment-1',
      companyId: 'company-1',
      invoiceId: 'invoice-1',
      customerId: 'customer-1',
      paymentMethodId: 'method-1',
      paymentDate: DateTime.utc(2026, 8, 10),
      amountMinorUnits: 40000,
      currencyCode: 'AED',
      referenceNumber: 'REF-1',
      createdAt: DateTime.utc(2026, 8, 10),
    ).toEntity();

    expect(entity.amount.minorUnits, 40000);
    expect(entity.amount.currency.value, 'AED');
    expect(entity.referenceNumber, 'REF-1');
  });

  test('rejects invalid persisted payment amount', () {
    final model = PaymentModel(
      id: 'payment-1',
      companyId: 'company-1',
      invoiceId: 'invoice-1',
      customerId: 'customer-1',
      paymentMethodId: 'method-1',
      paymentDate: DateTime.utc(2026, 8, 10),
      amountMinorUnits: 0,
      currencyCode: 'AED',
      createdAt: DateTime.utc(2026, 8, 10),
    );

    expect(model.toEntity, throwsFormatException);
  });
}
