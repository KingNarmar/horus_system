class CustomerModel {
  final String id;
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
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CustomerModel({
    required this.id,
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
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory CustomerModel.fromMap(Map<String, dynamic> map) {
    return CustomerModel(
      id: map['id'] as String,
      companyId: map['company_id'] as String,
      name: map['name'] as String,
      contactPerson: map['contact_person'] as String?,
      phone: map['phone'] as String?,
      email: map['email'] as String?,
      taxRegistrationNumber: map['tax_registration_number'] as String?,
      address: map['address'] as String?,
      city: map['city'] as String?,
      country: map['country'] as String?,
      creditLimit: _toDouble(map['credit_limit']),
      isActive: map['is_active'] as bool? ?? true,
      createdAt: _toDateTime(map['created_at']),
      updatedAt: _toDateTime(map['updated_at']),
    );
  }

  static double? _toDouble(Object? value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static DateTime? _toDateTime(Object? value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}
