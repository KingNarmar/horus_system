class CustomerWriteData {
  final String companyId;
  final String name;
  final String? contactPerson;
  final String? phone;
  final String? email;
  final String? taxRegistrationNumber;
  final String? address;
  final String? city;
  final String? country;
  final double? creditLimit;

  const CustomerWriteData({
    required this.companyId,
    required this.name,
    this.contactPerson,
    this.phone,
    this.email,
    this.taxRegistrationNumber,
    this.address,
    this.city,
    this.country,
    this.creditLimit,
  });
}
