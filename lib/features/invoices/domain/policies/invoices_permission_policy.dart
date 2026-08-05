import '../../../company/domain/entities/company_role.dart';

abstract final class InvoicesPermissionPolicy {
  static bool canViewInvoices(CompanyRole role) {
    return switch (role) {
      CompanyRole.owner ||
      CompanyRole.admin ||
      CompanyRole.operations ||
      CompanyRole.accountant ||
      CompanyRole.viewer => true,
      CompanyRole.driver => false,
    };
  }

  static bool canManageInvoiceDrafts(CompanyRole role) {
    return switch (role) {
      CompanyRole.owner || CompanyRole.admin || CompanyRole.accountant => true,
      CompanyRole.operations ||
      CompanyRole.viewer ||
      CompanyRole.driver => false,
    };
  }

  static bool canIssueInvoices(CompanyRole role) {
    return canManageInvoiceDrafts(role);
  }

  static bool canCancelInvoices(CompanyRole role) {
    return canManageInvoiceDrafts(role);
  }
}
