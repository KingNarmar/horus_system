import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/current_company_context.dart';
import '../repositories/company_context_repository.dart';

class LoadCurrentCompanyContextUseCase
    implements UseCase<CurrentCompanyContext?, NoParams> {
  final CompanyContextRepository _repository;

  const LoadCurrentCompanyContextUseCase(this._repository);

  @override
  Future<Result<CurrentCompanyContext?>> call(NoParams params) async {
    final result = await _repository.loadUserCompanyContexts();

    return result.when(
      success: (contexts) async {
        if (contexts.isEmpty) {
          await _repository.clearCurrentCompanyContext();
          return const Success<CurrentCompanyContext?>(null);
        }

        final selectedResult = await _repository.selectCompany(
          contexts.first.companyId,
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
