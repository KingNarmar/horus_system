import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../repositories/pending_company_invitation_repository.dart';

class ClearPendingCompanyInvitationUseCase implements UseCase<void, NoParams> {
  final PendingCompanyInvitationRepository _repository;

  const ClearPendingCompanyInvitationUseCase(this._repository);

  @override
  Future<Result<void>> call(NoParams params) {
    return _repository.clearToken();
  }
}
