import '../../../../core/errors/failure.dart';
import '../../domain/entities/company_invitation.dart';

sealed class CompanyInvitationsState {
  final String? companyId;

  const CompanyInvitationsState({this.companyId});
}

class CompanyInvitationsInitial extends CompanyInvitationsState {
  const CompanyInvitationsInitial();
}

class CompanyInvitationsLoading extends CompanyInvitationsState {
  const CompanyInvitationsLoading({required super.companyId});
}

class CompanyInvitationsLoaded extends CompanyInvitationsState {
  final List<CompanyInvitation> invitations;

  const CompanyInvitationsLoaded({
    required super.companyId,
    required this.invitations,
  });
}

class CompanyInvitationsCommandInProgress extends CompanyInvitationsState {
  final List<CompanyInvitation> invitations;

  const CompanyInvitationsCommandInProgress({
    required super.companyId,
    required this.invitations,
  });
}

class CompanyInvitationsFailure extends CompanyInvitationsState {
  final Failure failure;
  final List<CompanyInvitation> invitations;

  const CompanyInvitationsFailure({
    required super.companyId,
    required this.failure,
    required this.invitations,
  });
}
