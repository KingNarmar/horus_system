final class InvoicePrefix {
  static final RegExp _pattern = RegExp(r'^[A-Z][A-Z0-9-]{0,15}$');

  final String value;

  const InvoicePrefix._(this.value);

  static InvoicePrefix? tryParse(String rawValue) {
    final normalized = rawValue.trim().toUpperCase();
    if (!_pattern.hasMatch(normalized)) return null;
    return InvoicePrefix._(normalized);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is InvoicePrefix && other.value == value;
  }

  @override
  int get hashCode => value.hashCode;
}
