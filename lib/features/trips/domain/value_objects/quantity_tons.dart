final class QuantityTons {
  static const int fractionDigits = 3;
  static const int scale = 1000;
  static final RegExp _decimalPattern = RegExp(r'^\d+(?:\.\d+)?$');
  static final BigInt _maxSignedBigInt = BigInt.parse('9223372036854775807');

  final int scaledUnits;

  const QuantityTons._(this.scaledUnits);

  bool get isZero => scaledUnits == 0;
  bool get isPositive => scaledUnits > 0;

  static QuantityTons? tryParse(String input) {
    final value = input.trim();
    if (value.isEmpty || !_decimalPattern.hasMatch(value)) return null;

    final parts = value.split('.');
    final wholePart = parts.first;
    final fractionPart = parts.length == 2 ? parts[1] : '';
    if (fractionPart.length > fractionDigits) return null;

    final digits = '$wholePart${fractionPart.padRight(fractionDigits, '0')}';
    final scaledUnits = BigInt.tryParse(digits);
    if (scaledUnits == null || scaledUnits > _maxSignedBigInt) return null;

    return QuantityTons._(scaledUnits.toInt());
  }

  String toDecimalString() {
    final whole = scaledUnits ~/ scale;
    final fraction = (scaledUnits % scale).toString().padLeft(
      fractionDigits,
      '0',
    );
    return '$whole.$fraction';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is QuantityTons && other.scaledUnits == scaledUnits;
  }

  @override
  int get hashCode => scaledUnits.hashCode;
}
