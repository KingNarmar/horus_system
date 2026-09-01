import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/company_invitation.dart';
import '../../domain/entities/company_role.dart';
import '../../domain/entities/current_company_context.dart';
import '../../domain/failures/company_failure_codes.dart';
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
    await _loadInvitations(currentCompanyContext);
  }

  Future<void> send({
    required CurrentCompanyContext currentCompanyContext,
    required String email,
    required CompanyRole role,
  }) async {
    final companyId = currentCompanyContext.companyId;
    _scopeCompanyId = companyId;
    final invitations = _currentInvitations(companyId);
    emit(
      CompanyInvitationsCommandInProgress(
        companyId: companyId,
        invitations: invitations,
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
      success: (_) => _handleCommandSuccess(currentCompanyContext, invitations),
      failure: (failure) => _handleCommandFailure(
        currentCompanyContext,
        failure,
        invitations,
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
    Future<Result<void>> Function() action,
  ) async {
    final companyId = context.companyId;
    _scopeCompanyId = companyId;
    final invitations = _currentInvitations(companyId);
    emit(
      CompanyInvitationsCommandInProgress(
        companyId: companyId,
        invitations: invitations,
      ),
    );

    final result = await action();
    if (_scopeCompanyId != companyId) return;

    await result.when(
      success: (_) => _handleCommandSuccess(context, invitations),
      failure: (failure) => _handleCommandFailure(
        context,
        failure,
        invitations,
      ),
    );
  }

  Future<void> _handleCommandSuccess(
    CurrentCompanyContext context,
    List<CompanyInvitation> invitations,
  ) async {
    final companyId = context.companyId;
    if (_scopeCompanyId != companyId) return;

    emit(
      CompanyInvitationsCommandSucceeded(
        companyId: companyId,
        invitations: invitations,
      ),
    );
    await _loadInvitations(context);
  }

  Future<void> _handleCommandFailure(
    CurrentCompanyContext context,
    Failure failure,
    List<CompanyInvitation> invitations,
  ) async {
    final companyId = context.companyId;
    if (_scopeCompanyId != companyId) return;

    emit(
      CompanyInvitationsCommandFailure(
        companyId: companyId,
        failure: failure,
        invitations: invitations,
      ),
    );

    if (!_requiresAuthoritativeRefresh(failure.code)) return;

    final refreshResult = await _getInvitationsUseCase(
      GetCompanyInvitationsParams(currentCompanyContext: context),
    );
    if (_scopeCompanyId != companyId) return;

    refreshResult.when(
      success: (refreshedInvitations) => emit(
        CompanyInvitationsLoaded(
          companyId: companyId,
          invitations: refreshedInvitations,
        ),
      ),
      failure: (_) {},
    );
  }

  bool _requiresAuthoritativeRefresh(String failureCode) {
    return failureCode == CompanyFailureCodes.invitationDeliveryFailed ||
        failureCode ==
            CompanyFailureCodes.invitationDeliveryConfirmationUnknown;
  }

  Future<void> _loadInvitations(CurrentCompanyContext context) async {
    final companyId = context.companyId;
    final result = await _getInvitationsUseCase(
      GetCompanyInvitationsParams(currentCompanyContext: context),
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
        CompanyInvitationsLoadFailure(companyId: companyId, failure: failure),
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
    if (current is CompanyInvitationsCommandSucceeded) {
      return current.invitations;
    }
    if (current is CompanyInvitationsCommandFailure) {
      return current.invitations;
    }
    return const [];
  }
}
