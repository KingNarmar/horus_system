import '../../../company/domain/entities/company_role.dart';

abstract final class DriverSettlementsPermissionPolicy {
  static bool canViewDriverSettlements(CompanyRole role) {
    return switch (role) {
      CompanyRole.owner || CompanyRole.admin || CompanyRole.accountant => true,
      CompanyRole.operations || CompanyRole.viewer || CompanyRole.driver => false,
    };
  }

  static bool canManageDriverSettlements(CompanyRole role) {
    return switch (role) {
      CompanyRole.owner || CompanyRole.admin || CompanyRole.accountant => true,
      CompanyRole.operations || CompanyRole.viewer || CompanyRole.driver => false,
    };
  }

  static bool canFinalizeDriverSettlements(CompanyRole role) {
    return canManageDriverSettlements(role);
  }

  static bool canVoidDriverSettlements(CompanyRole role) {
    return canManageDriverSettlements(role);
  }
}
