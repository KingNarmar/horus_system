import '../../../../core/errors/failure.dart';
import '../../domain/entities/company_invitation_preview.dart';

sealed class CompanyInvitationAcceptanceState {
  const CompanyInvitationAcceptanceState();
}

class CompanyInvitationAcceptanceInitial
    extends CompanyInvitationAcceptanceState {
  const CompanyInvitationAcceptanceInitial();
}

class CompanyInvitationAwaitingAuthentication
    extends CompanyInvitationAcceptanceState {
  const CompanyInvitationAwaitingAuthentication();
}

class CompanyInvitationPreviewLoading
    extends CompanyInvitationAcceptanceState {
  const CompanyInvitationPreviewLoading();
}

class CompanyInvitationPreviewReady
    extends CompanyInvitationAcceptanceState {
  final CompanyInvitationPreview preview;

  const CompanyInvitationPreviewReady(this.preview);
}

class CompanyInvitationAccepting extends CompanyInvitationAcceptanceState {
  final CompanyInvitationPreview preview;

  const CompanyInvitationAccepting(this.preview);
}

class CompanyInvitationAccepted extends CompanyInvitationAcceptanceState {
  final String companyId;
  final Failure? pendingTokenCleanupFailure;

  const CompanyInvitationAccepted(
    this.companyId, {
    this.pendingTokenCleanupFailure,
  });
}

class CompanyInvitationAcceptanceFailure
    extends CompanyInvitationAcceptanceState {
  final Failure failure;

  const CompanyInvitationAcceptanceFailure(this.failure);
}
