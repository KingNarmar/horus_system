class CompanyModel {
  final String id;
  final String name;
  final String? businessType;
  final String? phone;
  final String? email;
  final String? country;
  final String? city;
  final String? logoUrl;
  final bool isActive;

  const CompanyModel({
    required this.id,
    required this.name,
    this.businessType,
    this.phone,
    this.email,
    this.country,
    this.city,
    this.logoUrl,
    this.isActive = true,
  });

  factory CompanyModel.fromMap(Map<String, dynamic> map) {
    return CompanyModel(
      id: map['id'] as String,
      name: map['name'] as String,
      businessType: map['business_type'] as String?,
      phone: map['phone'] as String?,
      email: map['email'] as String?,
      country: map['country'] as String?,
      city: map['city'] as String?,
      logoUrl: map['logo_url'] as String?,
      isActive: map['is_active'] as bool? ?? true,
    );
  }
}
