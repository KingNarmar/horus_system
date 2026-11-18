class CompanyBrandProfile {
  final String companyId;
  final String name;
  final String? businessType;
  final String? phone;
  final String? email;
  final String? country;
  final String? city;
  final String? address;
  final String? taxRegistrationNumber;
  final String? logoPath;
  final DateTime updatedAt;

  const CompanyBrandProfile({
    required this.companyId,
    required this.name,
    required this.updatedAt,
    this.businessType,
    this.phone,
    this.email,
    this.country,
    this.city,
    this.address,
    this.taxRegistrationNumber,
    this.logoPath,
  });
}
