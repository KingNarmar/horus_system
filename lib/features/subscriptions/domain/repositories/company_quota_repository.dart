import '../../../../core/utils/result.dart';
import '../entities/company_quota_snapshot.dart';

abstract interface class CompanyQuotaRepository {
  Future<Result<CompanyQuotaSnapshot>> getUsage({required String companyId});
}
