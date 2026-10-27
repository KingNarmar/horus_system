import '../../../../core/utils/result.dart';
import '../entities/company_membership_change.dart';

abstract interface class CompanyMembershipChangesRepository {
  Stream<Result<CompanyMembershipChange>> watchChanges({
    required String userId,
  });
}
