import 'package:horus_system/core/domain/value_objects/currency_code.dart';
import 'package:horus_system/features/payments/domain/services/payment_amount_parser.dart';
import 'package:test/test.dart';

void main() {
  final currency = CurrencyCode.tryParse('AED')!;

  test('parses decimal amounts directly into minor units', () {
    final money = PaymentAmountParser.tryParse(
      rawValue: '1200.50',
      currency: currency,
      fractionDigits: 2,
    );

    expect(money?.minorUnits, 120050);
    expect(money?.currency, currency);
  });

  test('supports valid western and Arabic grouping and digits', () {
    final western = PaymentAmountParser.tryParse(
      rawValue: '1,200.50',
      currency: currency,
      fractionDigits: 2,
    );
    final arabic = PaymentAmountParser.tryParse(
      rawValue: '١٬٢٠٠٫٥٠',
      currency: currency,
      fractionDigits: 2,
    );

    expect(western?.minorUnits, 120050);
    expect(arabic?.minorUnits, 120050);
  });

  test('rejects ambiguous grouping and excessive currency precision', () {
    expect(
      PaymentAmountParser.tryParse(
        rawValue: '1,20.00',
        currency: currency,
        fractionDigits: 2,
      ),
      isNull,
    );
    expect(
      PaymentAmountParser.tryParse(
        rawValue: '10.001',
        currency: currency,
        fractionDigits: 2,
      ),
      isNull,
    );
  });

  test('rejects values outside signed bigint minor-unit storage', () {
    expect(
      PaymentAmountParser.tryParse(
        rawValue: '92233720368547758.08',
        currency: currency,
        fractionDigits: 2,
      ),
      isNull,
    );
  });

  test('preserves non-positive values for the use case positive rule', () {
    final zero = PaymentAmountParser.tryParse(
      rawValue: '0',
      currency: currency,
      fractionDigits: 2,
    );
    final negative = PaymentAmountParser.tryParse(
      rawValue: '-25.50',
      currency: currency,
      fractionDigits: 2,
    );

    expect(zero?.minorUnits, 0);
    expect(negative?.minorUnits, -2550);
  });
}
