import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure_codes.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/current_company_context.dart';
import '../repositories/company_context_repository.dart';

class RefreshSelectedCompanyContextParams {
  final String companyId;

  const RefreshSelectedCompanyContextParams({required this.companyId});
}

class RefreshSelectedCompanyContextUseCase
    implements
        UseCase<CurrentCompanyContext, RefreshSelectedCompanyContextParams> {
  final CompanyContextRepository _repository;

  const RefreshSelectedCompanyContextUseCase(this._repository);

  @override
  Future<Result<CurrentCompanyContext>> call(
    RefreshSelectedCompanyContextParams params,
  ) async {
    final companyId = params.companyId.trim();
    if (companyId.isEmpty) {
      return const FailureResult(
        ValidationFailure(
          code: FailureCodes.validationCompanyContextRequired,
        ),
      );
    }

    final refreshResult = await _repository.loadUserCompanyContexts();
    final refreshFailure = refreshResult.failureOrNull;
    if (refreshFailure != null) {
      return FailureResult(refreshFailure);
    }

    return _repository.selectCompany(companyId);
  }
}
