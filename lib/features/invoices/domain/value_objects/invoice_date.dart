import '../../../../core/domain/value_objects/business_date.dart';

final class InvoiceDate implements Comparable<InvoiceDate> {
  final BusinessDate value;

  const InvoiceDate._(this.value);

  factory InvoiceDate.fromBusinessDate(BusinessDate date) {
    return InvoiceDate._(date);
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
