/// Explicit finite/unlimited distinction. Missing data is never unlimited.
final class EntitlementLimit {
  final int? value;

  const EntitlementLimit._(this.value);

  factory EntitlementLimit.finite(int value) {
    if (value < 0) {
      throw ArgumentError.value(value, 'value', 'Limit cannot be negative');
    }
    return EntitlementLimit._(value);
  }

  const EntitlementLimit.unlimited() : value = null;

  bool get isUnlimited => value == null;

  bool allowsAdditional({required int currentUsage, int additional = 1}) {
    if (currentUsage < 0 || additional < 0) return false;
    final cap = value;
    return cap == null || currentUsage + additional <= cap;
  }
}
