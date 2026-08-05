final class InvoiceCustomerSnapshot {
  final String companyId;
  final String customerId;
  final String name;
  final String? taxRegistrationNumber;
  final String? address;
  final String? city;
  final String? country;

  const InvoiceCustomerSnapshot({
    required this.companyId,
    required this.customerId,
    required this.name,
    this.taxRegistrationNumber,
    this.address,
    this.city,
    this.country,
  });

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is InvoiceCustomerSnapshot &&
            other.companyId == companyId &&
            other.customerId == customerId &&
            other.name == name &&
            other.taxRegistrationNumber == taxRegistrationNumber &&
            other.address == address &&
            other.city == city &&
            other.country == country;
  }

  @override
  int get hashCode => Object.hash(
    companyId,
    customerId,
    name,
    taxRegistrationNumber,
    address,
    city,
    country,
  );
}
