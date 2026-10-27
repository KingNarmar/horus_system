import '../../../../core/errors/common_failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/company_membership_change.dart';
import '../failures/company_failure_codes.dart';
import '../repositories/company_membership_changes_repository.dart';

final class WatchCompanyMembershipChangesParams {
  final String userId;

  const WatchCompanyMembershipChangesParams({required this.userId});
}

/// Emits refresh hints, never an authoritative role or active flag.
final class WatchCompanyMembershipChangesUseCase
    implements
        StreamUseCase<
          CompanyMembershipChange,
          WatchCompanyMembershipChangesParams
        > {
  final CompanyMembershipChangesRepository _repository;

  const WatchCompanyMembershipChangesUseCase(this._repository);

  @override
  Stream<Result<CompanyMembershipChange>> call(
    WatchCompanyMembershipChangesParams params,
  ) {
    final userId = params.userId.trim();
    if (userId.isEmpty) {
      return Stream.value(
        const FailureResult(
          ValidationFailure(code: CompanyFailureCodes.authRequired),
        ),
      );
    }
    return _repository.watchChanges(userId: userId);
  }
}
