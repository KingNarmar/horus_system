import '../../../../core/errors/common_failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/current_company_context.dart';
import '../failures/company_failure_codes.dart';
import '../policies/company_selection_policy.dart';
import '../repositories/selected_company_preference_repository.dart';
import '../repositories/company_context_repository.dart';

/// Identity is supplied by the authenticated session, never by the switcher.
final class LoadCurrentCompanyContextParams extends NoParams {
  final String userId;

  const LoadCurrentCompanyContextParams({required this.userId});
}

class LoadCurrentCompanyContextUseCase
    implements UseCase<CurrentCompanyContext?, NoParams> {
  final CompanyContextRepository _repository;
  final SelectedCompanyPreferenceRepository? _preferences;

  const LoadCurrentCompanyContextUseCase(
    this._repository, {
    SelectedCompanyPreferenceRepository? preferences,
  }) : _preferences = preferences;

  @override
  Future<Result<CurrentCompanyContext?>> call(NoParams params) async {
    final result = await _repository.loadUserCompanyContexts();

    return result.when(
      success: (contexts) async {
        if (contexts.isEmpty) {
          await _repository.clearCurrentCompanyContext();
          return const Success<CurrentCompanyContext?>(null);
        }

        String? preferredCompanyId;
        if (params is LoadCurrentCompanyContextParams && _preferences != null) {
          if (params.userId.trim().isEmpty) {
            return const FailureResult<CurrentCompanyContext?>(
              AuthFailure(code: CompanyFailureCodes.authRequired),
            );
          }
          final preferenceResult = await _preferences.read(params.userId);
          final preferenceFailure = preferenceResult.failureOrNull;
          if (preferenceFailure is AuthFailure) {
            // Identity mismatch cannot fall back to a different user.
            return FailureResult<CurrentCompanyContext?>(preferenceFailure);
          }
          // A device preference is optional. On a local storage failure,
          // choose only from the freshly validated server memberships.
          if (preferenceFailure == null) {
            preferredCompanyId = preferenceResult.dataOrNull;
          }
        }

        final selectedCompanyId = CompanySelectionPolicy.chooseCompanyId(
          activeContexts: contexts,
          preferredCompanyId: preferredCompanyId,
        );
        final selectedResult = await _repository.selectCompany(
          selectedCompanyId,
        );

        return selectedResult.when(
          success: (context) => Success<CurrentCompanyContext?>(context),
          failure: (failure) => FailureResult<CurrentCompanyContext?>(failure),
        );
      },
      failure: (failure) async =>
          FailureResult<CurrentCompanyContext?>(failure),
    );
  }
}
