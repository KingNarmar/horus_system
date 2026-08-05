final class InvoiceNumber {
  static final RegExp _pattern = RegExp(
    r'^[A-Z][A-Z0-9-]{0,15}-[0-9]{4}-[0-9]{6}$',
  );

  final String value;

  const InvoiceNumber._(this.value);

  static InvoiceNumber? tryParse(String rawValue) {
    final normalized = rawValue.trim().toUpperCase();
    if (!_pattern.hasMatch(normalized)) return null;
    return InvoiceNumber._(normalized);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is InvoiceNumber && other.value == value;
  }

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}
