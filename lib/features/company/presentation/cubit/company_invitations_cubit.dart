import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/company_invitation.dart';
import '../../domain/entities/company_role.dart';
import '../../domain/entities/current_company_context.dart';
import '../../domain/usecases/get_company_invitations_usecase.dart';
import '../../domain/usecases/resend_company_invitation_usecase.dart';
import '../../domain/usecases/revoke_company_invitation_usecase.dart';
import '../../domain/usecases/send_company_invitation_usecase.dart';
import 'company_invitations_state.dart';

class CompanyInvitationsCubit extends Cubit<CompanyInvitationsState> {
  final GetCompanyInvitationsUseCase _getInvitationsUseCase;
  final SendCompanyInvitationUseCase _sendInvitationUseCase;
  final ResendCompanyInvitationUseCase _resendInvitationUseCase;
  final RevokeCompanyInvitationUseCase _revokeInvitationUseCase;

  String? _scopeCompanyId;

  CompanyInvitationsCubit({
    required GetCompanyInvitationsUseCase getInvitationsUseCase,
    required SendCompanyInvitationUseCase sendInvitationUseCase,
    required ResendCompanyInvitationUseCase resendInvitationUseCase,
    required RevokeCompanyInvitationUseCase revokeInvitationUseCase,
  }) : _getInvitationsUseCase = getInvitationsUseCase,
       _sendInvitationUseCase = sendInvitationUseCase,
       _resendInvitationUseCase = resendInvitationUseCase,
       _revokeInvitationUseCase = revokeInvitationUseCase,
       super(const CompanyInvitationsInitial());

  Future<void> load(CurrentCompanyContext currentCompanyContext) async {
    final companyId = currentCompanyContext.companyId;
    _scopeCompanyId = companyId;
    emit(CompanyInvitationsLoading(companyId: companyId));

    final result = await _getInvitationsUseCase(
      GetCompanyInvitationsParams(
        currentCompanyContext: currentCompanyContext,
      ),
    );

    if (_scopeCompanyId != companyId) return;

    result.when(
      success: (invitations) => emit(
        CompanyInvitationsLoaded(
          companyId: companyId,
          invitations: invitations,
        ),
      ),
      failure: (failure) => emit(
        CompanyInvitationsFailure(companyId: companyId, failure: failure),
      ),
    );
  }

  Future<void> send({
    required CurrentCompanyContext currentCompanyContext,
    required String email,
    required CompanyRole role,
  }) async {
    final companyId = currentCompanyContext.companyId;
    _scopeCompanyId = companyId;
    emit(
      CompanyInvitationsCommandInProgress(
        companyId: companyId,
        invitations: _currentInvitations(companyId),
      ),
    );

    final result = await _sendInvitationUseCase(
      SendCompanyInvitationParams(
        currentCompanyContext: currentCompanyContext,
        email: email,
        role: role,
      ),
    );

    if (_scopeCompanyId != companyId) return;

    await result.when(
      success: (_) => load(currentCompanyContext),
      failure: (failure) async => emit(
        CompanyInvitationsFailure(companyId: companyId, failure: failure),
      ),
    );
  }

  Future<void> resend({
    required CurrentCompanyContext currentCompanyContext,
    required String invitationId,
  }) async {
    await _runCommand(
      currentCompanyContext,
      () => _resendInvitationUseCase(
        ResendCompanyInvitationParams(
          currentCompanyContext: currentCompanyContext,
          invitationId: invitationId,
        ),
      ),
    );
  }

  Future<void> revoke({
    required CurrentCompanyContext currentCompanyContext,
    required String invitationId,
  }) async {
    await _runCommand(
      currentCompanyContext,
      () => _revokeInvitationUseCase(
        RevokeCompanyInvitationParams(
          currentCompanyContext: currentCompanyContext,
          invitationId: invitationId,
        ),
      ),
    );
  }

  Future<void> _runCommand(
    CurrentCompanyContext context,
    Future<dynamic> Function() action,
  ) async {
    final companyId = context.companyId;
    _scopeCompanyId = companyId;
    emit(
      CompanyInvitationsCommandInProgress(
        companyId: companyId,
        invitations: _currentInvitations(companyId),
      ),
    );

    final result = await action();
    if (_scopeCompanyId != companyId) return;

    await result.when(
      success: (_) => load(context),
      failure: (failure) async => emit(
        CompanyInvitationsFailure(companyId: companyId, failure: failure),
      ),
    );
  }

  List<CompanyInvitation> _currentInvitations(String companyId) {
    final current = state;
    if (current.companyId != companyId) return const [];
    if (current is CompanyInvitationsLoaded) return current.invitations;
    if (current is CompanyInvitationsCommandInProgress) {
      return current.invitations;
    }
    return const [];
  }
}
