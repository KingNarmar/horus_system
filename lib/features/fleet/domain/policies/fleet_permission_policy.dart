import '../../../company/domain/entities/company_role.dart';

abstract final class FleetPermissionPolicy {
  static bool canViewFleet(CompanyRole role) {
    return switch (role) {
      CompanyRole.owner ||
      CompanyRole.admin ||
      CompanyRole.operations ||
      CompanyRole.accountant ||
      CompanyRole.viewer => true,
      CompanyRole.driver => false,
    };
  }

  static bool canManageFleet(CompanyRole role) {
    return switch (role) {
      CompanyRole.owner || CompanyRole.admin || CompanyRole.operations => true,
      CompanyRole.accountant || CompanyRole.viewer || CompanyRole.driver => false,
    };
  }
}
