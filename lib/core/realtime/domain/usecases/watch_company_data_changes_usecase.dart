import '../../../errors/common_failures.dart';
import '../../../errors/failure_codes.dart';
import '../../../usecases/usecase.dart';
import '../../../utils/result.dart';
import '../entities/company_data_change.dart';
import '../repositories/company_data_changes_repository.dart';

final class WatchCompanyDataChangesParams {
  final String companyId;

  const WatchCompanyDataChangesParams({required this.companyId});
}

final class WatchCompanyDataChangesUseCase
    implements StreamUseCase<CompanyDataChange, WatchCompanyDataChangesParams> {
  final CompanyDataChangesRepository _repository;

  const WatchCompanyDataChangesUseCase(this._repository);

  @override
  Stream<Result<CompanyDataChange>> call(WatchCompanyDataChangesParams params) {
    final companyId = params.companyId.trim();
    if (companyId.isEmpty) {
      return Stream.value(
        const FailureResult(
          ValidationFailure(code: FailureCodes.validationCompanyIdRequired),
        ),
      );
    }
    return _repository.watchChanges(companyId: companyId);
  }
}
