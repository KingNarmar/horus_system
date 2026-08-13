import '../../../company/domain/entities/company_role.dart';

abstract final class ReportsPermissionPolicy {
  static bool canViewOperationalReports(CompanyRole role) {
    return switch (role) {
      CompanyRole.owner ||
      CompanyRole.admin ||
      CompanyRole.operations ||
      CompanyRole.accountant ||
      CompanyRole.viewer => true,
      CompanyRole.driver => false,
    };
  }

  static bool canViewFinancialReports(CompanyRole role) {
    return switch (role) {
      CompanyRole.owner || CompanyRole.admin || CompanyRole.accountant => true,
      CompanyRole.operations || CompanyRole.viewer || CompanyRole.driver =>
        false,
    };
  }

  static bool canViewOpenInvoicesReport(CompanyRole role) {
    return canViewOperationalReports(role);
  }
}
