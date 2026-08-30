import '../../../../core/utils/result.dart';
import '../entities/company_role.dart';

abstract class CompanyMembershipRepository {
  Future<Result<void>> changeRole({
    required String companyId,
    required String membershipId,
    required CompanyRole newRole,
  });

  Future<Result<void>> deactivate({
    required String companyId,
    required String membershipId,
  });

  Future<Result<void>> reactivate({
    required String companyId,
    required String membershipId,
  });

  Future<Result<void>> grantOwnership({
    required String companyId,
    required String membershipId,
  });

  Future<Result<void>> transferOwnership({
    required String companyId,
    required String targetMembershipId,
    required CompanyRole sourceNewRole,
  });
}
