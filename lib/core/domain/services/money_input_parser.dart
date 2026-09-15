final class MoneyInputParser {
  static final RegExp _decimalPattern = RegExp(r'^\d+(?:\.\d+)?$');
  static final BigInt _maxSignedBigInt = BigInt.from(9223372036854775807);

  const MoneyInputParser();

  int? tryParseMinorUnits(String input, {required int fractionDigits}) {
    if (fractionDigits < 0) return null;

    final value = input.trim();
    if (value.isEmpty || !_decimalPattern.hasMatch(value)) return null;

    final parts = value.split('.');
    final wholePart = parts.first;
    final fractionPart = parts.length == 2 ? parts[1] : '';
    if (fractionPart.length > fractionDigits) return null;

    final digits = '$wholePart${fractionPart.padRight(fractionDigits, '0')}';
    final minorUnits = BigInt.tryParse(digits);
    if (minorUnits == null || minorUnits > _maxSignedBigInt) return null;

    return minorUnits.toInt();
  }
}
