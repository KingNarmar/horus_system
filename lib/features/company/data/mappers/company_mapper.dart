import '../../domain/entities/company.dart';
import '../models/company_model.dart';

extension CompanyModelMapper on CompanyModel {
  Company toEntity() {
    return Company(
      id: id,
      name: name,
      businessType: businessType,
      phone: phone,
      email: email,
      country: country,
      city: city,
      logoUrl: logoUrl,
      baseCurrencyCode: baseCurrencyCode,
      baseCurrencyFractionDigits: baseCurrencyFractionDigits,
      businessTimezone: businessTimezone,
      isActive: isActive,
    );
  }
}
