import '../value_objects/currency_configuration.dart';
import '../value_objects/money.dart';
import 'money_input_parser.dart';

final class MoneyDecimalCodec {
  final MoneyInputParser _parser;

  const MoneyDecimalCodec({MoneyInputParser parser = const MoneyInputParser()})
    : _parser = parser;

  Money? tryDecodeNonNegative(
    String? input, {
    required CurrencyConfiguration configuration,
  }) {
    if (input == null) return null;

    final minorUnits = _parser.tryParseMinorUnits(
      input,
      fractionDigits: configuration.fractionDigits,
    );
    if (minorUnits == null) return null;

    return Money(minorUnits: minorUnits, currency: configuration.currency);
  }

  String encode(
    Money money, {
    required CurrencyConfiguration configuration,
  }) {
    if (money.currency != configuration.currency) {
      throw ArgumentError('Money currency does not match configuration.');
    }

    final fractionDigits = configuration.fractionDigits;
    final isNegative = money.minorUnits < 0;
    final absoluteMinorUnits = money.minorUnits.abs();
    if (fractionDigits == 0) {
      return '${isNegative ? '-' : ''}$absoluteMinorUnits';
    }

    final scale = _pow10(fractionDigits);
    final whole = absoluteMinorUnits ~/ scale;
    final fraction = (absoluteMinorUnits % scale).toString().padLeft(
      fractionDigits,
      '0',
    );
    return '${isNegative ? '-' : ''}$whole.$fraction';
  }

  String encodeNonNegative(
    Money money, {
    required CurrencyConfiguration configuration,
  }) {
    if (money.isNegative) {
      throw ArgumentError.value(
        money.minorUnits,
        'money',
        'Money must not be negative.',
      );
    }
    return encode(money, configuration: configuration);
  }

  int _pow10(int exponent) {
    var result = 1;
    for (var index = 0; index < exponent; index += 1) {
      result *= 10;
    }
    return result;
  }
}
