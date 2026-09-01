import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/result.dart';
import '../../domain/entities/company_role.dart';
import '../../domain/entities/current_company_context.dart';
import '../../domain/usecases/change_company_member_role_usecase.dart';
import '../../domain/usecases/deactivate_company_member_usecase.dart';
import '../../domain/usecases/grant_company_ownership_usecase.dart';
import '../../domain/usecases/reactivate_company_member_usecase.dart';
import '../../domain/usecases/transfer_company_ownership_usecase.dart';
import 'company_member_actions_state.dart';

class CompanyMemberActionsCubit extends Cubit<CompanyMemberActionsState> {
  final ChangeCompanyMemberRoleUseCase _changeRoleUseCase;
  final DeactivateCompanyMemberUseCase _deactivateUseCase;
  final ReactivateCompanyMemberUseCase _reactivateUseCase;
  final GrantCompanyOwnershipUseCase _grantOwnershipUseCase;
  final TransferCompanyOwnershipUseCase _transferOwnershipUseCase;

  String? _scopeCompanyId;

  CompanyMemberActionsCubit({
    required ChangeCompanyMemberRoleUseCase changeRoleUseCase,
    required DeactivateCompanyMemberUseCase deactivateUseCase,
    required ReactivateCompanyMemberUseCase reactivateUseCase,
    required GrantCompanyOwnershipUseCase grantOwnershipUseCase,
    required TransferCompanyOwnershipUseCase transferOwnershipUseCase,
  }) : _changeRoleUseCase = changeRoleUseCase,
       _deactivateUseCase = deactivateUseCase,
       _reactivateUseCase = reactivateUseCase,
       _grantOwnershipUseCase = grantOwnershipUseCase,
       _transferOwnershipUseCase = transferOwnershipUseCase,
       super(const CompanyMemberActionsInitial());

  Future<void> changeRole({
    required CurrentCompanyContext currentCompanyContext,
    required String membershipId,
    required CompanyRole currentRole,
    required CompanyRole newRole,
  }) {
    return _run(
      currentCompanyContext.companyId,
      () => _changeRoleUseCase(
        ChangeCompanyMemberRoleParams(
          currentCompanyContext: currentCompanyContext,
          membershipId: membershipId,
          currentRole: currentRole,
          newRole: newRole,
        ),
      ),
    );
  }

  Future<void> deactivate({
    required CurrentCompanyContext currentCompanyContext,
    required String membershipId,
    required CompanyRole targetRole,
  }) {
    return _run(
      currentCompanyContext.companyId,
      () => _deactivateUseCase(
        DeactivateCompanyMemberParams(
          currentCompanyContext: currentCompanyContext,
          membershipId: membershipId,
          targetRole: targetRole,
        ),
      ),
    );
  }

  Future<void> reactivate({
    required CurrentCompanyContext currentCompanyContext,
    required String membershipId,
    required CompanyRole targetRole,
  }) {
    return _run(
      currentCompanyContext.companyId,
      () => _reactivateUseCase(
        ReactivateCompanyMemberParams(
          currentCompanyContext: currentCompanyContext,
          membershipId: membershipId,
          targetRole: targetRole,
        ),
      ),
    );
  }

  Future<void> grantOwnership({
    required CurrentCompanyContext currentCompanyContext,
    required String membershipId,
  }) {
    return _run(
      currentCompanyContext.companyId,
      () => _grantOwnershipUseCase(
        GrantCompanyOwnershipParams(
          currentCompanyContext: currentCompanyContext,
          membershipId: membershipId,
        ),
      ),
    );
  }

  Future<void> transferOwnership({
    required CurrentCompanyContext currentCompanyContext,
    required String targetMembershipId,
    required CompanyRole sourceNewRole,
  }) {
    return _run(
      currentCompanyContext.companyId,
      () => _transferOwnershipUseCase(
        TransferCompanyOwnershipParams(
          currentCompanyContext: currentCompanyContext,
          targetMembershipId: targetMembershipId,
          sourceNewRole: sourceNewRole,
        ),
      ),
    );
  }

  Future<void> _run(
    String companyId,
    Future<Result<void>> Function() action,
  ) async {
    _scopeCompanyId = companyId;
    emit(CompanyMemberActionInProgress(companyId: companyId));

    final result = await action();
    if (_scopeCompanyId != companyId) return;

    result.when(
      success: (_) => emit(CompanyMemberActionSucceeded(companyId: companyId)),
      failure: (failure) => emit(
        CompanyMemberActionFailed(companyId: companyId, failure: failure),
      ),
    );
  }
}
