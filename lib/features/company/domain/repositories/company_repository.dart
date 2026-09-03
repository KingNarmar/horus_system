import '../../../../core/utils/result.dart';
import '../entities/company.dart';
import '../value_objects/company_timezone.dart';

abstract class CompanyRepository {
  Future<Result<Company>> createCompany({
    required String name,
    required CompanyTimezone businessTimezone,
    String? businessType,
    String? phone,
    String? email,
    String? country,
    String? city,
  });

  Future<Result<List<Company>>> getMyCompanies();
}
