import '../../../../core/utils/result.dart';
import '../entities/company_entitlement.dart';

/// Read-only entitlement capability. Administrative mutations belong to #358.
abstract interface class CompanyEntitlementsRepository {
  Future<Result<CompanyEntitlement>> getCurrent({required String companyId});
}
