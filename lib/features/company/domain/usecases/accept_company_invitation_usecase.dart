import '../../../../core/errors/common_failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../failures/company_failure_codes.dart';
import '../repositories/company_invitations_repository.dart';

class AcceptCompanyInvitationUseCase implements UseCase<String, String> {
  final CompanyInvitationsRepository _repository;

  const AcceptCompanyInvitationUseCase(this._repository);

  @override
  Future<Result<String>> call(String token) {
    final normalizedToken = token.trim();
    if (normalizedToken.isEmpty) {
      return Future.value(
        const FailureResult(
          ValidationFailure(code: CompanyFailureCodes.invitationInvalid),
        ),
      );
    }

    return _repository.acceptInvitation(normalizedToken);
  }
}
