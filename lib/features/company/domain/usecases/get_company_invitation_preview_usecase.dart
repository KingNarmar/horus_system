import '../../../../core/errors/common_failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/company_invitation_preview.dart';
import '../failures/company_failure_codes.dart';
import '../repositories/company_invitations_repository.dart';

class GetCompanyInvitationPreviewUseCase
    implements UseCase<CompanyInvitationPreview, String> {
  final CompanyInvitationsRepository _repository;

  const GetCompanyInvitationPreviewUseCase(this._repository);

  @override
  Future<Result<CompanyInvitationPreview>> call(String token) {
    final normalizedToken = token.trim();
    if (normalizedToken.isEmpty) {
      return Future.value(
        const FailureResult(
          ValidationFailure(code: CompanyFailureCodes.invitationInvalid),
        ),
      );
    }

    return _repository.getInvitationPreview(normalizedToken);
  }
}
