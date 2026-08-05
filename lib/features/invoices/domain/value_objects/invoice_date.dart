final class InvoiceDate implements Comparable<InvoiceDate> {
  final DateTime value;

  InvoiceDate._(this.value);

  factory InvoiceDate.fromDateTime(DateTime dateTime) {
    return InvoiceDate._(
      DateTime.utc(dateTime.year, dateTime.month, dateTime.day),
    );
  }

  bool isAfter(InvoiceDate other) => value.isAfter(other.value);
  bool isBefore(InvoiceDate other) => value.isBefore(other.value);

  @override
  int compareTo(InvoiceDate other) => value.compareTo(other.value);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is InvoiceDate && other.value == value;
  }

  @override
  int get hashCode => value.hashCode;
}
