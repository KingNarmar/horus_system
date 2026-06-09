import '../../../../core/utils/result.dart';
import '../entities/company.dart';

abstract class CompanyRepository {
  Future<Result<Company>> createCompany({
    required String name,
    String? businessType,
    String? phone,
    String? email,
    String? country,
    String? city,
  });

  Future<Result<List<Company>>> getMyCompanies();
}
