import '../../../../core/utils/result.dart';
import '../entities/current_company_context.dart';

abstract class CompanyContextRepository {
  Future<Result<List<CurrentCompanyContext>>> loadUserCompanyContexts();

  Future<Result<CurrentCompanyContext>> selectCompany(String companyId);

  Future<Result<CurrentCompanyContext?>> getCurrentCompanyContext();

  Future<Result<void>> clearCurrentCompanyContext();
}
