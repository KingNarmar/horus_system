import '../entities/company_role.dart';

abstract final class CompanyMembershipManagementPolicy {
  static bool canChangeRole({
    required CompanyRole actorRole,
    required CompanyRole targetRole,
    required CompanyRole newRole,
  }) {
    return actorRole == CompanyRole.owner &&
        targetRole != CompanyRole.owner &&
        newRole != CompanyRole.owner;
  }

  static bool canChangeActiveStatus({
    required CompanyRole actorRole,
    required CompanyRole targetRole,
  }) {
    if (targetRole == CompanyRole.owner) {
      return false;
    }

    return switch (actorRole) {
      CompanyRole.owner => true,
      CompanyRole.admin => targetRole != CompanyRole.admin,
      _ => false,
    };
  }

  static bool canManageOwnership(CompanyRole actorRole) {
    return actorRole == CompanyRole.owner;
  }
}
