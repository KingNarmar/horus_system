final class CompanyTimezone {
  static const int _maximumLength = 128;
  static final RegExp _pattern = RegExp(
    r'^[A-Za-z0-9._+-]+(?:/[A-Za-z0-9._+-]+)*$',
  );

  final String value;

  const CompanyTimezone._(this.value);

  static CompanyTimezone? tryParse(String rawValue) {
    final normalized = rawValue.trim();
    if (normalized.isEmpty || normalized.length > _maximumLength) {
      return null;
    }
    if (!_pattern.hasMatch(normalized)) return null;
    return CompanyTimezone._(normalized);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is CompanyTimezone && other.value == value;
  }

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}
