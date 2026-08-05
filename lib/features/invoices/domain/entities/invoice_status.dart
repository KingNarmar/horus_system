enum InvoiceStatus {
  draft('draft'),
  issued('issued'),
  cancelled('cancelled');

  final String value;

  const InvoiceStatus(this.value);

  static InvoiceStatus? tryFromValue(String rawValue) {
    final normalized = rawValue.trim().toLowerCase();
    for (final status in InvoiceStatus.values) {
      if (status.value == normalized) return status;
    }
    return null;
  }
}
