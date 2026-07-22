import '../../../company/domain/entities/company_role.dart';

abstract final class DriverFinancePermissionPolicy {
  static bool canViewDriverFinance(CompanyRole role) {
    return switch (role) {
      CompanyRole.owner ||
      CompanyRole.admin ||
      CompanyRole.operations ||
      CompanyRole.accountant ||
      CompanyRole.viewer => true,
      CompanyRole.driver => false,
    };
  }

  static bool canManageDriverFinance(CompanyRole role) {
    return switch (role) {
      CompanyRole.owner || CompanyRole.admin || CompanyRole.accountant => true,
      CompanyRole.operations ||
      CompanyRole.viewer ||
      CompanyRole.driver => false,
    };
  }
}
