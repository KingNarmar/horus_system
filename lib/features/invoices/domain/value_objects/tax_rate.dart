final class TaxRate {
  static const int maximumBasisPoints = 10000;

  final int basisPoints;

  const TaxRate._(this.basisPoints);

  static TaxRate? tryCreate(int basisPoints) {
    if (basisPoints < 0 || basisPoints > maximumBasisPoints) return null;
    return TaxRate._(basisPoints);
  }

  bool get isZero => basisPoints == 0;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is TaxRate && other.basisPoints == basisPoints;
  }

  @override
  int get hashCode => basisPoints.hashCode;
}
