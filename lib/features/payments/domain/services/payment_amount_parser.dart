import '../../../../core/domain/value_objects/currency_code.dart';
import '../../../../core/domain/value_objects/money.dart';

abstract final class PaymentAmountParser {
  static final BigInt _maxMinorUnits = BigInt.parse('9223372036854775807');

  static Money? tryParse({
    required String rawValue,
    required CurrencyCode currency,
    required int fractionDigits,
  }) {
    if (fractionDigits < 0 || fractionDigits > 4) return null;

    var normalized = _normalizeDigits(rawValue.trim());
    normalized = normalized.replaceAll('٫', '.').replaceAll('٬', ',');

    final isNegative = normalized.startsWith('-');
    if (isNegative) normalized = normalized.substring(1);

    normalized = _normalizeGrouping(normalized);
    if (normalized.isEmpty) return null;
    if (normalized.startsWith('.')) normalized = '0$normalized';

    if (!RegExp(r'^\d+(?:\.\d*)?$').hasMatch(normalized)) return null;

    final parts = normalized.split('.');
    final wholePart = parts.first;
    final fractionPart = parts.length == 1 ? '' : parts.last;
    if (fractionPart.length > fractionDigits) return null;

    final scale = BigInt.from(10).pow(fractionDigits);
    final whole = BigInt.tryParse(wholePart);
    final paddedFraction = fractionPart.padRight(fractionDigits, '0');
    final fraction = BigInt.tryParse(
      paddedFraction.isEmpty ? '0' : paddedFraction,
    );
    if (whole == null || fraction == null) return null;

    final absoluteMinorUnits = whole * scale + fraction;
    if (absoluteMinorUnits > _maxMinorUnits) return null;

    final minorUnits = isNegative ? -absoluteMinorUnits : absoluteMinorUnits;
    return Money(minorUnits: minorUnits.toInt(), currency: currency);
  }

  static String _normalizeGrouping(String value) {
    if (!value.contains(',')) return value;
    if (!RegExp(r'^\d{1,3}(?:,\d{3})+(?:\.\d*)?$').hasMatch(value)) {
      return '';
    }
    return value.replaceAll(',', '');
  }

  static String _normalizeDigits(String value) {
    const arabicIndic = '٠١٢٣٤٥٦٧٨٩';
    const easternArabicIndic = '۰۱۲۳۴۵۶۷۸۹';
    const western = '0123456789';

    final buffer = StringBuffer();
    for (final rune in value.runes) {
      final character = String.fromCharCode(rune);
      final arabicIndex = arabicIndic.indexOf(character);
      if (arabicIndex >= 0) {
        buffer.write(western[arabicIndex]);
        continue;
      }
      final easternIndex = easternArabicIndic.indexOf(character);
      if (easternIndex >= 0) {
        buffer.write(western[easternIndex]);
        continue;
      }
      buffer.write(character);
    }
    return buffer.toString();
  }
}
