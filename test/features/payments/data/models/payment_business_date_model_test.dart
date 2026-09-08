import 'package:horus_system/core/domain/value_objects/business_date.dart';
import 'package:horus_system/features/payments/data/models/payment_model.dart';
import 'package:test/test.dart';

void main() {
  group('Payment business-date parsing', () {
    Map<String, dynamic> baseMap({Object? paymentDate = '2026-09-07'}) {
      return {
        'id': 'payment-1',
        'company_id': 'company-1',
        'invoice_id': 'invoice-1',
        'customer_id': 'customer-1',
        'payment_method_id': 'method-1',
        'payment_date': paymentDate,
        'amount_minor_units': 12500,
        'currency_code': 'AED',
        'created_at': '2026-09-07T08:30:00.000Z',
      };
    }

    test('model preserves exact payment calendar date', () {
      final model = PaymentModel.fromMap(baseMap());

      expect(
        model.paymentDate,
        BusinessDate(year: 2026, month: 9, day: 7),
      );
      expect(model.createdAt, DateTime.utc(2026, 9, 7, 8, 30));
    });

    test('model rejects timestamp-shaped payment date', () {
      expect(
        () => PaymentModel.fromMap(
          baseMap(paymentDate: '2026-09-07T00:00:00Z'),
        ),
        throwsFormatException,
      );
    });
  });
}
