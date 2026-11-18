import '../../../../core/data/constants/db_common_fields.dart';
import '../../domain/entities/company_brand_profile.dart';
import '../constants/company_db_fields.dart';

final class CompanyBrandProfileModel {
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

  const CompanyBrandProfileModel({
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

  factory CompanyBrandProfileModel.fromMap(Map<String, dynamic> values) {
    return CompanyBrandProfileModel(
      companyId: values[DbCommonFields.id] as String,
      name: values[CompanyDbFields.name] as String,
      updatedAt: DateTime.parse(values[DbCommonFields.updatedAt] as String),
      businessType: values[CompanyDbFields.businessType] as String?,
      phone: values[CompanyDbFields.phone] as String?,
      email: values[CompanyDbFields.email] as String?,
      country: values[CompanyDbFields.country] as String?,
      city: values[CompanyDbFields.city] as String?,
      address: values[CompanyDbFields.address] as String?,
      taxRegistrationNumber:
          values[CompanyDbFields.taxRegistrationNumber] as String?,
      logoPath: values[CompanyDbFields.logoUrl] as String?,
    );
  }

  CompanyBrandProfile toEntity() => CompanyBrandProfile(
    companyId: companyId,
    name: name,
    updatedAt: updatedAt,
    businessType: businessType,
    phone: phone,
    email: email,
    country: country,
    city: city,
    address: address,
    taxRegistrationNumber: taxRegistrationNumber,
    logoPath: logoPath,
  );
}
