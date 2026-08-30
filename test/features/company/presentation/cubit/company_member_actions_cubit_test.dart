import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/entities/current_company_context.dart';
import 'package:horus_system/features/company/domain/repositories/company_membership_repository.dart';
import 'package:horus_system/features/company/domain/usecases/change_company_member_role_usecase.dart';
import 'package:horus_system/features/company/domain/usecases/deactivate_company_member_usecase.dart';
import 'package:horus_system/features/company/domain/usecases/grant_company_ownership_usecase.dart';
import 'package:horus_system/features/company/domain/usecases/reactivate_company_member_usecase.dart';
import 'package:horus_system/features/company/domain/usecases/transfer_company_ownership_usecase.dart';
import 'package:horus_system/features/company/presentation/cubit/company_member_actions_cubit.dart';
import 'package:horus_system/features/company/presentation/cubit/company_member_actions_state.dart';

void main() {
  test('change role keeps the captured company scope', () async {
    final repository = _FakeCompanyMembershipRepository();
    final cubit = _buildCubit(repository);
    addTearDown(cubit.close);

    await cubit.changeRole(
      currentCompanyContext: _context('company-a'),
      membershipId: ' membership-1 ',
      currentRole: CompanyRole.viewer,
      newRole: CompanyRole.admin,
    );

    expect(repository.lastCompanyId, 'company-a');
    expect(repository.lastMembershipId, 'membership-1');
    expect(repository.lastRole, CompanyRole.admin);
    final state = cubit.state;
    expect(state, isA<CompanyMemberActionSucceeded>());
    expect(state.companyId, 'company-a');
  });

  test('repository failure is exposed as typed action failure', () async {
    final repository = _FakeCompanyMembershipRepository()
      ..nextResult = const FailureResult(
        ServerFailure(code: FailureCodes.serverError),
      );
    final cubit = _buildCubit(repository);
    addTearDown(cubit.close);

    await cubit.reactivate(
      currentCompanyContext: _context('company-a'),
      membershipId: 'membership-1',
      targetRole: CompanyRole.viewer,
    );

    final state = cubit.state;
    expect(state, isA<CompanyMemberActionFailed>());
    expect(state.companyId, 'company-a');
    expect(
      (state as CompanyMemberActionFailed).failure.code,
      FailureCodes.serverError,
    );
  });

  test(
    'late response from an older company cannot overwrite newer scope',
    () async {
      final repository = _FakeCompanyMembershipRepository();
      final companyAResult = Completer<Result<void>>();
      repository.deferredResults['company-a'] = companyAResult;

      final cubit = _buildCubit(repository);
      addTearDown(cubit.close);

      final companyAFuture = cubit.changeRole(
        currentCompanyContext: _context('company-a'),
        membershipId: 'member-a',
        currentRole: CompanyRole.viewer,
        newRole: CompanyRole.admin,
      );

      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.companyId, 'company-a');
      expect(cubit.state, isA<CompanyMemberActionInProgress>());

      await cubit.changeRole(
        currentCompanyContext: _context('company-b'),
        membershipId: 'member-b',
        currentRole: CompanyRole.viewer,
        newRole: CompanyRole.admin,
      );

      expect(cubit.state, isA<CompanyMemberActionSucceeded>());
      expect(cubit.state.companyId, 'company-b');

      companyAResult.complete(const Success(null));
      await companyAFuture;

      expect(cubit.state, isA<CompanyMemberActionSucceeded>());
      expect(cubit.state.companyId, 'company-b');
    },
  );
}

CompanyMemberActionsCubit _buildCubit(CompanyMembershipRepository repository) {
  return CompanyMemberActionsCubit(
    changeRoleUseCase: ChangeCompanyMemberRoleUseCase(repository),
    deactivateUseCase: DeactivateCompanyMemberUseCase(repository),
    reactivateUseCase: ReactivateCompanyMemberUseCase(repository),
    grantOwnershipUseCase: GrantCompanyOwnershipUseCase(repository),
    transferOwnershipUseCase: TransferCompanyOwnershipUseCase(repository),
  );
}

CurrentCompanyContext _context(String companyId) {
  return CurrentCompanyContext(
    company: Company(id: companyId, name: companyId),
    role: CompanyRole.owner,
  );
}

class _FakeCompanyMembershipRepository implements CompanyMembershipRepository {
  Result<void> nextResult = const Success(null);
  final Map<String, Completer<Result<void>>> deferredResults = {};

  String? lastCompanyId;
  String? lastMembershipId;
  CompanyRole? lastRole;

  Future<Result<void>> _resultFor(String companyId) {
    return deferredResults[companyId]?.future ?? Future.value(nextResult);
  }

  @override
  Future<Result<void>> changeRole({
    required String companyId,
    required String membershipId,
    required CompanyRole newRole,
  }) {
    lastCompanyId = companyId;
    lastMembershipId = membershipId;
    lastRole = newRole;
    return _resultFor(companyId);
  }

  @override
  Future<Result<void>> deactivate({
    required String companyId,
    required String membershipId,
  }) {
    lastCompanyId = companyId;
    lastMembershipId = membershipId;
    return _resultFor(companyId);
  }

  @override
  Future<Result<void>> grantOwnership({
    required String companyId,
    required String membershipId,
  }) {
    lastCompanyId = companyId;
    lastMembershipId = membershipId;
    return _resultFor(companyId);
  }

  @override
  Future<Result<void>> reactivate({
    required String companyId,
    required String membershipId,
  }) {
    lastCompanyId = companyId;
    lastMembershipId = membershipId;
    return _resultFor(companyId);
  }

  @override
  Future<Result<void>> transferOwnership({
    required String companyId,
    required String targetMembershipId,
    required CompanyRole sourceNewRole,
  }) {
    lastCompanyId = companyId;
    lastMembershipId = targetMembershipId;
    lastRole = sourceNewRole;
    return _resultFor(companyId);
  }
}
