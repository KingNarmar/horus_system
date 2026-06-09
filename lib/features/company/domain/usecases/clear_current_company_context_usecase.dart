import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../repositories/company_context_repository.dart';

class ClearCurrentCompanyContextUseCase implements UseCase<void, NoParams> {
  final CompanyContextRepository _repository;

  const ClearCurrentCompanyContextUseCase(this._repository);

  @override
  Future<Result<void>> call(NoParams params) {
    return _repository.clearCurrentCompanyContext();
  }
}
