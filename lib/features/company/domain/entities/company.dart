class Company {
  final String id;
  final String name;
  final String? businessType;
  final String? phone;
  final String? email;
  final String? country;
  final String? city;
  final String? logoUrl;
  final String? baseCurrencyCode;
  final int? baseCurrencyFractionDigits;
  final String? businessTimezone;
  final bool isActive;

  const Company({
    required this.id,
    required this.name,
    this.businessType,
    this.phone,
    this.email,
    this.country,
    this.city,
    this.logoUrl,
    this.baseCurrencyCode,
    this.baseCurrencyFractionDigits,
    this.businessTimezone,
    this.isActive = true,
  });

  bool get hasCompleteRegionalSettings {
    return baseCurrencyCode != null &&
        baseCurrencyFractionDigits != null &&
        businessTimezone != null;
  }
}
