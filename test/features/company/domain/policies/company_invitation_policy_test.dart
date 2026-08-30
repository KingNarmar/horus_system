import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/policies/company_invitation_policy.dart';
import 'package:test/test.dart';

void main() {
  group('CompanyInvitationPolicy', () {
    test('owner can invite admin and lower roles but never owner', () {
      expect(
        CompanyInvitationPolicy.canInviteRole(
          actorRole: CompanyRole.owner,
          targetRole: CompanyRole.admin,
        ),
        isTrue,
      );
      expect(
        CompanyInvitationPolicy.canInviteRole(
          actorRole: CompanyRole.owner,
          targetRole: CompanyRole.owner,
        ),
        isFalse,
      );
    });

    test('admin cannot invite admin or owner', () {
      expect(
        CompanyInvitationPolicy.canInviteRole(
          actorRole: CompanyRole.admin,
          targetRole: CompanyRole.admin,
        ),
        isFalse,
      );
      expect(
        CompanyInvitationPolicy.canInviteRole(
          actorRole: CompanyRole.admin,
          targetRole: CompanyRole.owner,
        ),
        isFalse,
      );
      expect(
        CompanyInvitationPolicy.canInviteRole(
          actorRole: CompanyRole.admin,
          targetRole: CompanyRole.operations,
        ),
        isTrue,
      );
    });

    test('non managers cannot invite or view invitations', () {
      for (final role in const [
        CompanyRole.operations,
        CompanyRole.accountant,
        CompanyRole.viewer,
        CompanyRole.driver,
      ]) {
        expect(CompanyInvitationPolicy.canViewInvitations(role), isFalse);
        expect(CompanyInvitationPolicy.assignableRoles(role), isEmpty);
      }
    });
  });
}
