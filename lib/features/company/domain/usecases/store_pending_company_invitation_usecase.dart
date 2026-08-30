import '../../../../core/errors/common_failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../failures/company_failure_codes.dart';
import '../repositories/pending_company_invitation_repository.dart';

class StorePendingCompanyInvitationUseCase implements UseCase<void, String> {
  final PendingCompanyInvitationRepository _repository;

  const StorePendingCompanyInvitationUseCase(this._repository);

  @override
  Future<Result<void>> call(String token) {
    final normalizedToken = token.trim();
    if (normalizedToken.isEmpty) {
      return Future.value(
        const FailureResult(
          ValidationFailure(code: CompanyFailureCodes.invitationInvalid),
        ),
      );
    }

    return _repository.storeToken(normalizedToken);
  }
}
