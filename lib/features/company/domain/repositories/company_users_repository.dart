import '../../../../core/utils/result.dart';
import '../entities/company_user.dart';

abstract class CompanyUsersRepository {
  Future<Result<List<CompanyUser>>> getCompanyUsers();
}
