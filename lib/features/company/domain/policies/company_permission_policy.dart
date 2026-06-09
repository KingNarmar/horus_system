import '../entities/company_permissions.dart';
import '../entities/company_role.dart';

abstract final class CompanyPermissionPolicy {
  static CompanyPermissions permissionsFor(CompanyRole role) {
    return CompanyPermissions(
      canViewCompanyUsers: canViewCompanyUsers(role),
      canInviteCompanyUsers: canInviteCompanyUsers(role),
      canChangeCompanyUserRole: canChangeCompanyUserRole(role),
      canDeactivateCompanyUser: canDeactivateCompanyUser(role),
      canManageCompanySettings: canManageCompanySettings(role),
    );
  }

  static bool canViewCompanyUsers(CompanyRole role) {
    return role == CompanyRole.owner || role == CompanyRole.admin;
  }

  static bool canInviteCompanyUsers(CompanyRole role) {
    return role == CompanyRole.owner || role == CompanyRole.admin;
  }

  static bool canChangeCompanyUserRole(CompanyRole role) {
    return role == CompanyRole.owner;
  }

  static bool canDeactivateCompanyUser(CompanyRole role) {
    return role == CompanyRole.owner || role == CompanyRole.admin;
  }

  static bool canManageCompanySettings(CompanyRole role) {
    return role == CompanyRole.owner || role == CompanyRole.admin;
  }
}
