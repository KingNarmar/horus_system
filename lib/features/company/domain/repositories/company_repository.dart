import '../../../../core/domain/value_objects/invoice_prefix.dart';
import '../../../../core/utils/result.dart';
import '../entities/company.dart';
import '../entities/company_financial_configuration.dart';
import '../value_objects/company_timezone.dart';

abstract class CompanyRepository {
  Future<Result<Company>> createCompany({
    required String name,
    required CompanyTimezone businessTimezone,
    required CompanyFinancialConfiguration financialConfiguration,
    required InvoicePrefix invoicePrefix,
    String? businessType,
    String? phone,
    String? email,
    String? country,
    String? city,
  });

  Future<Result<List<Company>>> getMyCompanies();
}
