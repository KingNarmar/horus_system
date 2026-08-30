import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/policies/company_membership_management_policy.dart';
import 'package:test/test.dart';

void main() {
  group('CompanyMembershipManagementPolicy', () {
    test('only owner can change non-owner roles to non-owner roles', () {
      expect(
        CompanyMembershipManagementPolicy.canChangeRole(
          actorRole: CompanyRole.owner,
          targetRole: CompanyRole.operations,
          newRole: CompanyRole.admin,
        ),
        isTrue,
      );
      expect(
        CompanyMembershipManagementPolicy.canChangeRole(
          actorRole: CompanyRole.admin,
          targetRole: CompanyRole.operations,
          newRole: CompanyRole.viewer,
        ),
        isFalse,
      );
      expect(
        CompanyMembershipManagementPolicy.canChangeRole(
          actorRole: CompanyRole.owner,
          targetRole: CompanyRole.owner,
          newRole: CompanyRole.admin,
        ),
        isFalse,
      );
      expect(
        CompanyMembershipManagementPolicy.canChangeRole(
          actorRole: CompanyRole.owner,
          targetRole: CompanyRole.operations,
          newRole: CompanyRole.owner,
        ),
        isFalse,
      );
    });

    test('admin can change status only for lower roles', () {
      expect(
        CompanyMembershipManagementPolicy.canChangeActiveStatus(
          actorRole: CompanyRole.admin,
          targetRole: CompanyRole.operations,
        ),
        isTrue,
      );
      expect(
        CompanyMembershipManagementPolicy.canChangeActiveStatus(
          actorRole: CompanyRole.admin,
          targetRole: CompanyRole.admin,
        ),
        isFalse,
      );
      expect(
        CompanyMembershipManagementPolicy.canChangeActiveStatus(
          actorRole: CompanyRole.admin,
          targetRole: CompanyRole.owner,
        ),
        isFalse,
      );
    });

    test('owner can change lower-role status but not owner status', () {
      expect(
        CompanyMembershipManagementPolicy.canChangeActiveStatus(
          actorRole: CompanyRole.owner,
          targetRole: CompanyRole.admin,
        ),
        isTrue,
      );
      expect(
        CompanyMembershipManagementPolicy.canChangeActiveStatus(
          actorRole: CompanyRole.owner,
          targetRole: CompanyRole.owner,
        ),
        isFalse,
      );
    });

    test('only owner can manage ownership', () {
      expect(
        CompanyMembershipManagementPolicy.canManageOwnership(
          CompanyRole.owner,
        ),
        isTrue,
      );
      for (final role in const [
        CompanyRole.admin,
        CompanyRole.operations,
        CompanyRole.accountant,
        CompanyRole.viewer,
        CompanyRole.driver,
      ]) {
        expect(
          CompanyMembershipManagementPolicy.canManageOwnership(role),
          isFalse,
        );
      }
    });
  });
}
