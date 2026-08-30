import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/entities/current_company_context.dart';
import 'package:horus_system/features/company/domain/failures/company_failure_codes.dart';
import 'package:horus_system/features/company/domain/repositories/company_membership_repository.dart';
import 'package:horus_system/features/company/domain/usecases/change_company_member_role_usecase.dart';
import 'package:horus_system/features/company/domain/usecases/deactivate_company_member_usecase.dart';
import 'package:horus_system/features/company/domain/usecases/grant_company_ownership_usecase.dart';
import 'package:horus_system/features/company/domain/usecases/reactivate_company_member_usecase.dart';
import 'package:horus_system/features/company/domain/usecases/transfer_company_ownership_usecase.dart';
import 'package:test/test.dart';

void main() {
  group('membership id validation', () {
    test('change role requires membership id', () async {
      final repository = _FakeCompanyMembershipRepository();
      final result = await ChangeCompanyMemberRoleUseCase(repository)(
        ChangeCompanyMemberRoleParams(
          currentCompanyContext: _context(CompanyRole.owner),
          membershipId: '   ',
          currentRole: CompanyRole.operations,
          newRole: CompanyRole.admin,
        ),
      );

      expect(
        result.failureOrNull?.code,
        CompanyFailureCodes.validationMembershipIdRequired,
      );
      expect(repository.changeRoleCalls, 0);
    });

    test('deactivate requires membership id', () async {
      final repository = _FakeCompanyMembershipRepository();
      final result = await DeactivateCompanyMemberUseCase(repository)(
        DeactivateCompanyMemberParams(
          currentCompanyContext: _context(CompanyRole.owner),
          membershipId: '',
          targetRole: CompanyRole.viewer,
        ),
      );

      expect(
        result.failureOrNull?.code,
        CompanyFailureCodes.validationMembershipIdRequired,
      );
      expect(repository.deactivateCalls, 0);
    });

    test('reactivate requires membership id', () async {
      final repository = _FakeCompanyMembershipRepository();
      final result = await ReactivateCompanyMemberUseCase(repository)(
        ReactivateCompanyMemberParams(
          currentCompanyContext: _context(CompanyRole.admin),
          membershipId: ' ',
          targetRole: CompanyRole.driver,
        ),
      );

      expect(
        result.failureOrNull?.code,
        CompanyFailureCodes.validationMembershipIdRequired,
      );
      expect(repository.reactivateCalls, 0);
    });

    test('grant ownership requires membership id', () async {
      final repository = _FakeCompanyMembershipRepository();
      final result = await GrantCompanyOwnershipUseCase(repository)(
        GrantCompanyOwnershipParams(
          currentCompanyContext: _context(CompanyRole.owner),
          membershipId: '',
        ),
      );

      expect(
        result.failureOrNull?.code,
        CompanyFailureCodes.validationMembershipIdRequired,
      );
      expect(repository.grantOwnershipCalls, 0);
    });

    test('transfer ownership requires target membership id', () async {
      final repository = _FakeCompanyMembershipRepository();
      final result = await TransferCompanyOwnershipUseCase(repository)(
        TransferCompanyOwnershipParams(
          currentCompanyContext: _context(CompanyRole.owner),
          targetMembershipId: '',
          sourceNewRole: CompanyRole.admin,
        ),
      );

      expect(
        result.failureOrNull?.code,
        CompanyFailureCodes.validationMembershipIdRequired,
      );
      expect(repository.transferOwnershipCalls, 0);
    });
  });

  group('membership permissions', () {
    test('admin cannot change roles', () async {
      final repository = _FakeCompanyMembershipRepository();
      final result = await ChangeCompanyMemberRoleUseCase(repository)(
        ChangeCompanyMemberRoleParams(
          currentCompanyContext: _context(CompanyRole.admin),
          membershipId: 'membership-1',
          currentRole: CompanyRole.operations,
          newRole: CompanyRole.viewer,
        ),
      );

      expect(
        result.failureOrNull?.code,
        CompanyFailureCodes.memberRoleChangeNotAllowed,
      );
      expect(repository.changeRoleCalls, 0);
    });

    test('admin cannot deactivate admin', () async {
      final repository = _FakeCompanyMembershipRepository();
      final result = await DeactivateCompanyMemberUseCase(repository)(
        DeactivateCompanyMemberParams(
          currentCompanyContext: _context(CompanyRole.admin),
          membershipId: 'membership-1',
          targetRole: CompanyRole.admin,
        ),
      );

      expect(
        result.failureOrNull?.code,
        CompanyFailureCodes.memberStatusChangeNotAllowed,
      );
      expect(repository.deactivateCalls, 0);
    });

    test('non-owner cannot grant ownership', () async {
      final repository = _FakeCompanyMembershipRepository();
      final result = await GrantCompanyOwnershipUseCase(repository)(
        GrantCompanyOwnershipParams(
          currentCompanyContext: _context(CompanyRole.admin),
          membershipId: 'membership-1',
        ),
      );

      expect(
        result.failureOrNull?.code,
        CompanyFailureCodes.ownershipTransferNotAllowed,
      );
      expect(repository.grantOwnershipCalls, 0);
    });

    test('owner cannot transfer ownership while remaining owner through this command', () async {
      final repository = _FakeCompanyMembershipRepository();
      final result = await TransferCompanyOwnershipUseCase(repository)(
        TransferCompanyOwnershipParams(
          currentCompanyContext: _context(CompanyRole.owner),
          targetMembershipId: 'membership-2',
          sourceNewRole: CompanyRole.owner,
        ),
      );

      expect(
        result.failureOrNull?.code,
        CompanyFailureCodes.ownershipTransferNotAllowed,
      );
      expect(repository.transferOwnershipCalls, 0);
    });
  });

  test('owner role change delegates normalized membership id', () async {
    final repository = _FakeCompanyMembershipRepository();
    final result = await ChangeCompanyMemberRoleUseCase(repository)(
      ChangeCompanyMemberRoleParams(
        currentCompanyContext: _context(CompanyRole.owner),
        membershipId: '  membership-1  ',
        currentRole: CompanyRole.viewer,
        newRole: CompanyRole.admin,
      ),
    );

    expect(result.isSuccess, isTrue);
    expect(repository.lastMembershipId, 'membership-1');
    expect(repository.lastRole, CompanyRole.admin);
    expect(repository.changeRoleCalls, 1);
  });
}

CurrentCompanyContext _context(CompanyRole role) {
  return CurrentCompanyContext(
    company: const Company(id: 'company-1', name: 'Company'),
    role: role,
  );
}

class _FakeCompanyMembershipRepository implements CompanyMembershipRepository {
  int changeRoleCalls = 0;
  int deactivateCalls = 0;
  int reactivateCalls = 0;
  int grantOwnershipCalls = 0;
  int transferOwnershipCalls = 0;
  String? lastMembershipId;
  CompanyRole? lastRole;

  @override
  Future<Result<void>> changeRole({
    required String companyId,
    required String membershipId,
    required CompanyRole newRole,
  }) async {
    changeRoleCalls += 1;
    lastMembershipId = membershipId;
    lastRole = newRole;
    return const Success(null);
  }

  @override
  Future<Result<void>> deactivate({
    required String companyId,
    required String membershipId,
  }) async {
    deactivateCalls += 1;
    lastMembershipId = membershipId;
    return const Success(null);
  }

  @override
  Future<Result<void>> grantOwnership({
    required String companyId,
    required String membershipId,
  }) async {
    grantOwnershipCalls += 1;
    lastMembershipId = membershipId;
    return const Success(null);
  }

  @override
  Future<Result<void>> reactivate({
    required String companyId,
    required String membershipId,
  }) async {
    reactivateCalls += 1;
    lastMembershipId = membershipId;
    return const Success(null);
  }

  @override
  Future<Result<void>> transferOwnership({
    required String companyId,
    required String targetMembershipId,
    required CompanyRole sourceNewRole,
  }) async {
    transferOwnershipCalls += 1;
    lastMembershipId = targetMembershipId;
    lastRole = sourceNewRole;
    return const Success(null);
  }
}
