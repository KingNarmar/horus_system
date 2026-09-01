import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../repositories/pending_company_invitation_repository.dart';

class GetPendingCompanyInvitationUseCase implements UseCase<String?, NoParams> {
  final PendingCompanyInvitationRepository _repository;

  const GetPendingCompanyInvitationUseCase(this._repository);

  @override
  Future<Result<String?>> call(NoParams params) {
    return _repository.getToken();
  }
}
