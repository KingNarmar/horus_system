import '../entities/company_role.dart';

abstract final class CompanyInvitationPolicy {
  static const Set<CompanyRole> _ownerAssignableRoles = {
    CompanyRole.admin,
    CompanyRole.operations,
    CompanyRole.accountant,
    CompanyRole.viewer,
    CompanyRole.driver,
  };

  static const Set<CompanyRole> _adminAssignableRoles = {
    CompanyRole.operations,
    CompanyRole.accountant,
    CompanyRole.viewer,
    CompanyRole.driver,
  };

  static bool canViewInvitations(CompanyRole actorRole) {
    return actorRole == CompanyRole.owner || actorRole == CompanyRole.admin;
  }

  static bool canInviteRole({
    required CompanyRole actorRole,
    required CompanyRole targetRole,
  }) {
    return switch (actorRole) {
      CompanyRole.owner => _ownerAssignableRoles.contains(targetRole),
      CompanyRole.admin => _adminAssignableRoles.contains(targetRole),
      _ => false,
    };
  }

  static List<CompanyRole> assignableRoles(CompanyRole actorRole) {
    final roles = switch (actorRole) {
      CompanyRole.owner => _ownerAssignableRoles,
      CompanyRole.admin => _adminAssignableRoles,
      _ => const <CompanyRole>{},
    };

    return List<CompanyRole>.unmodifiable(roles);
  }
}
