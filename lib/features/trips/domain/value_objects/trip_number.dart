final class TripNumber {
  static final RegExp _pattern = RegExp(
    r'^TRP-([0-9]{4})-([0-9]{6})

  final String value;

  const TripNumber._(this.value);

  static TripNumber? tryParse(String rawValue) {
    final normalized = rawValue.trim().toUpperCase();
    final match = _pattern.firstMatch(normalized);
    if (match == null) return null;

    final year = int.parse(match.group(1)!);
    final sequence = int.parse(match.group(2)!);
    if (year < 2000 || sequence < 1) return null;

    return TripNumber._(normalized);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is TripNumber && other.value == value;
  }

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}
,
  );

  final String value;

  const TripNumber._(this.value);

  static TripNumber? tryParse(String rawValue) {
    final normalized = rawValue.trim().toUpperCase();
    if (!_pattern.hasMatch(normalized)) return null;
    return TripNumber._(normalized);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is TripNumber && other.value == value;
  }

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}
