import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/current_company_context.dart';
import '../repositories/company_context_repository.dart';

/// Lists the caller's currently active company memberships and roles.
///
/// The repository performs an authoritative server read; this use case does
/// not infer authorization from the locally selected company.
final class GetSwitchableCompanyContextsUseCase
    implements UseCase<List<CurrentCompanyContext>, NoParams> {
  final CompanyContextRepository _repository;

  const GetSwitchableCompanyContextsUseCase(this._repository);

  @override
  Future<Result<List<CurrentCompanyContext>>> call(NoParams params) {
    return _repository.loadUserCompanyContexts();
  }
}
