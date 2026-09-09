final class CurrencyCode {
  static const int length = 3;
  static final RegExp _pattern = RegExp('^[A-Z]{$length}\$');

  final String value;

  const CurrencyCode._(this.value);

  static CurrencyCode? tryParse(String rawValue) {
    final normalized = rawValue.trim().toUpperCase();
    if (!_pattern.hasMatch(normalized)) return null;
    return CurrencyCode._(normalized);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is CurrencyCode && other.value == value;
  }

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}
