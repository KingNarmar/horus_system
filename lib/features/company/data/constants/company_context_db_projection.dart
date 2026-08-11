import '../../../../core/data/constants/db_common_fields.dart';
import 'company_db_fields.dart';

abstract class CompanyContextDbProjection {
  static const companyFields = <String>[
    DbCommonFields.id,
    CompanyDbFields.name,
    CompanyDbFields.businessType,
    CompanyDbFields.phone,
    CompanyDbFields.email,
    CompanyDbFields.country,
    CompanyDbFields.city,
    CompanyDbFields.logoUrl,
    CompanyDbFields.baseCurrencyCode,
    CompanyDbFields.baseCurrencyFractionDigits,
    CompanyDbFields.businessTimezone,
    DbCommonFields.isActive,
  ];

  static String get membershipSelect =>
      '${CompanyDbFields.role},${DbCommonFields.isActive},'
      '${CompanyDbFields.companiesTable}!inner(${companyFields.join(',')})';

  static String get activeCompanyFilter =>
      '${CompanyDbFields.companiesTable}.${DbCommonFields.isActive}';
}
