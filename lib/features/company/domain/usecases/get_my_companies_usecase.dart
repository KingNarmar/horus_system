import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/company.dart';
import '../repositories/company_repository.dart';

class GetMyCompaniesUseCase implements UseCase<List<Company>, NoParams> {
  final CompanyRepository _repository;

  const GetMyCompaniesUseCase(this._repository);

  @override
  Future<Result<List<Company>>> call(NoParams params) {
    return _repository.getMyCompanies();
  }
}
