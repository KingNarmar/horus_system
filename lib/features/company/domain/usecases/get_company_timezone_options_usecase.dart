import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../repositories/company_timezone_repository.dart';
import '../value_objects/company_timezone.dart';

final class GetCompanyTimezoneOptionsUseCase
    implements UseCase<List<CompanyTimezone>, NoParams> {
  final CompanyTimezoneRepository _repository;

  const GetCompanyTimezoneOptionsUseCase(this._repository);

  @override
  Future<Result<List<CompanyTimezone>>> call(NoParams params) {
    return _repository.getTimezoneOptions();
  }
}
