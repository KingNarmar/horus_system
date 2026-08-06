import '../../../../core/data/constants/db_common_fields.dart';
import '../constants/company_db_fields.dart';

class CompanyModel {
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

  const CompanyModel({
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

  factory CompanyModel.fromMap(Map<String, dynamic> map) {
    return CompanyModel(
      id: map[DbCommonFields.id] as String,
      name: map[CompanyDbFields.name] as String,
      businessType: map[CompanyDbFields.businessType] as String?,
      phone: map[CompanyDbFields.phone] as String?,
      email: map[CompanyDbFields.email] as String?,
      country: map[CompanyDbFields.country] as String?,
      city: map[CompanyDbFields.city] as String?,
      logoUrl: map[CompanyDbFields.logoUrl] as String?,
      baseCurrencyCode: map[CompanyDbFields.baseCurrencyCode] as String?,
      baseCurrencyFractionDigits:
          (map[CompanyDbFields.baseCurrencyFractionDigits] as num?)?.toInt(),
      businessTimezone: map[CompanyDbFields.businessTimezone] as String?,
      isActive: map[DbCommonFields.isActive] as bool? ?? true,
    );
  }
}
