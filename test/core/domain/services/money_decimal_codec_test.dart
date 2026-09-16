import 'package:horus_system/core/domain/services/money_decimal_codec.dart';
import 'package:horus_system/core/domain/value_objects/currency_configuration.dart';
import 'package:horus_system/core/domain/value_objects/money.dart';
import 'package:test/test.dart';

void main() {
  final aedConfiguration = CurrencyConfiguration.tryCreate(
    currencyCode: 'AED',
    fractionDigits: 2,
  )!;
  const codec = MoneyDecimalCodec();

  group('CurrencyConfiguration', () {
    test('normalizes a valid ISO-style currency code', () {
      final configuration = CurrencyConfiguration.tryCreate(
        currencyCode: ' aed ',
        fractionDigits: 2,
      );

      expect(configuration?.currency.value, 'AED');
      expect(configuration?.fractionDigits, 2);
    });

    test('rejects missing, malformed, and unsupported fraction digits', () {
      expect(
        CurrencyConfiguration.tryCreate(currencyCode: null, fractionDigits: 2),
        isNull,
      );
      expect(
        CurrencyConfiguration.tryCreate(currencyCode: 'AE', fractionDigits: 2),
        isNull,
      );
      expect(
        CurrencyConfiguration.tryCreate(currencyCode: 'AED', fractionDigits: 5),
        isNull,
      );
    });
  });

  group('MoneyDecimalCodec', () {
    test('decodes decimal text to exact minor units', () {
      expect(
        codec.tryDecodeNonNegative('125.05', configuration: aedConfiguration),
        Money(minorUnits: 12505, currency: aedConfiguration.currency),
      );
    });

    test('rejects over-precision, negative, and malformed values', () {
      expect(
        codec.tryDecodeNonNegative('1.001', configuration: aedConfiguration),
        isNull,
      );
      expect(
        codec.tryDecodeNonNegative('-1', configuration: aedConfiguration),
        isNull,
      );
      expect(
        codec.tryDecodeNonNegative('abc', configuration: aedConfiguration),
        isNull,
      );
    });

    test('encodes exact minor units without floating point', () {
      final money = Money(
        minorUnits: 12505,
        currency: aedConfiguration.currency,
      );

      expect(
        codec.encodeNonNegative(money, configuration: aedConfiguration),
        '125.05',
      );
    });

    test('supports zero-fraction currencies', () {
      final configuration = CurrencyConfiguration.tryCreate(
        currencyCode: 'JPY',
        fractionDigits: 0,
      )!;
      final money = Money(minorUnits: 125, currency: configuration.currency);

      expect(
        codec.encodeNonNegative(money, configuration: configuration),
        '125',
      );
    });

    test('rejects negative and mismatched-currency encoding', () {
      expect(
        () => codec.encodeNonNegative(
          Money(minorUnits: -1, currency: aedConfiguration.currency),
          configuration: aedConfiguration,
        ),
        throwsArgumentError,
      );

      final usdConfiguration = CurrencyConfiguration.tryCreate(
        currencyCode: 'USD',
        fractionDigits: 2,
      )!;
      expect(
        () => codec.encodeNonNegative(
          Money(minorUnits: 100, currency: usdConfiguration.currency),
          configuration: aedConfiguration,
        ),
        throwsArgumentError,
      );
    });
  });
}
