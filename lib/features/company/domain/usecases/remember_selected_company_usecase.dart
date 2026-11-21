import '../../../../core/errors/common_failures.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/usecases/usecase.dart';
import '../failures/company_failure_codes.dart';
import '../repositories/selected_company_preference_repository.dart';

final class RememberSelectedCompanyParams {
  final String userId;
  final String companyId;

  const RememberSelectedCompanyParams({
    required this.userId,
    required this.companyId,
  });
}

/// Persists only a company already verified by a separate authoritative
/// selection use case. Callers must not invoke this for unverified UI choices.
final class RememberSelectedCompanyUseCase
    implements UseCase<void, RememberSelectedCompanyParams> {
  final SelectedCompanyPreferenceRepository _preferences;

  const RememberSelectedCompanyUseCase(this._preferences);

  @override
  Future<Result<void>> call(RememberSelectedCompanyParams params) {
    final userId = params.userId.trim();
    if (userId.isEmpty) {
      return Future.value(
        const FailureResult(
          AuthFailure(code: CompanyFailureCodes.authRequired),
        ),
      );
    }
    final companyId = params.companyId.trim();
    if (companyId.isEmpty) {
      return Future.value(
        const FailureResult(
          ValidationFailure(code: CompanyFailureCodes.companyNotAvailable),
        ),
      );
    }
    return _preferences.save(userId: userId, companyId: companyId);
  }
}
