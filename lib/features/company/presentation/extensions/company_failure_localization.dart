import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/failures/company_failure_codes.dart';

extension CompanyFailureLocalizationX on AppLocalizations {
  String localizedCompanyErrorMessage(Failure failure) {
    return switch (failure.code) {
      CompanyFailureCodes.authRequired => failureCompanyAuthRequired,
      CompanyFailureCodes.validationInvitationIdRequired =>
        failureCompanyInvitationIdRequired,
      CompanyFailureCodes.validationInvitationTokenRequired =>
        failureCompanyInvitationTokenRequired,
      CompanyFailureCodes.validationMembershipIdRequired =>
        failureCompanyMembershipIdRequired,
      CompanyFailureCodes.invitationInvalid => failureCompanyInvitationInvalid,
      CompanyFailureCodes.invitationEmailInvalid =>
        failureCompanyInvitationEmailInvalid,
      CompanyFailureCodes.invitationExpired =>
        failureCompanyInvitationExpired,
      CompanyFailureCodes.invitationRevoked =>
        failureCompanyInvitationRevoked,
      CompanyFailureCodes.invitationAlreadyAccepted =>
        failureCompanyInvitationAlreadyAccepted,
      CompanyFailureCodes.invitationAlreadyPending =>
        failureCompanyInvitationAlreadyPending,
      CompanyFailureCodes.invitationEmailMismatch =>
        failureCompanyInvitationEmailMismatch,
      CompanyFailureCodes.invitationEmailNotVerified =>
        failureCompanyInvitationEmailNotVerified,
      CompanyFailureCodes.invitationRoleNotAllowed =>
        failureCompanyInvitationRoleNotAllowed,
      CompanyFailureCodes.invitationPermissionDenied =>
        failureCompanyInvitationPermissionDenied,
      CompanyFailureCodes.invitationDeliveryFailed =>
        failureCompanyInvitationDeliveryFailed,
      CompanyFailureCodes.invitationDeliveryConfirmationUnknown =>
        failureCompanyInvitationDeliveryConfirmationUnknown,
      CompanyFailureCodes.invitationDeliveryNotConfigured =>
        failureCompanyInvitationDeliveryNotConfigured,
      CompanyFailureCodes.memberAlreadyActive =>
        failureCompanyMemberAlreadyActive,
      CompanyFailureCodes.memberInactive => failureCompanyMemberInactive,
      CompanyFailureCodes.memberNotFound => failureCompanyMemberNotFound,
      CompanyFailureCodes.memberRoleChangeNotAllowed =>
        failureCompanyMemberRoleChangeNotAllowed,
      CompanyFailureCodes.memberStatusChangeNotAllowed =>
        failureCompanyMemberStatusChangeNotAllowed,
      CompanyFailureCodes.ownershipCommandRequired =>
        failureCompanyOwnershipCommandRequired,
      CompanyFailureCodes.ownershipTransferNotAllowed =>
        failureCompanyOwnershipTransferNotAllowed,
      CompanyFailureCodes.lastOwnerRequired => failureCompanyLastOwnerRequired,
      CompanyFailureCodes.notFound => failureCompanyNotAvailable,
      _ => _fallbackCompanyErrorMessage(failure),
    };
  }

  String _fallbackCompanyErrorMessage(Failure failure) {
    if (failure is AuthFailure) return failureAuthError;
    if (failure is ServerFailure) return failureServerError;
    if (failure is UnexpectedFailure) return failureUnexpectedError;

    return failureUnexpectedError;
  }
}
