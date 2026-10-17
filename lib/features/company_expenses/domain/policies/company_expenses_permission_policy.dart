import '../../../company/domain/entities/company_role.dart';

abstract final class CompanyExpensesPermissionPolicy {
  static bool canViewCompanyExpenses(CompanyRole role) {
    return switch (role) {
      CompanyRole.owner ||
      CompanyRole.admin ||
      CompanyRole.accountant => true,
      CompanyRole.operations ||
      CompanyRole.viewer ||
      CompanyRole.driver => false,
    };
  }

  static bool canManageCompanyExpenses(CompanyRole role) {
    return switch (role) {
      CompanyRole.owner || CompanyRole.admin || CompanyRole.accountant => true,
      CompanyRole.operations ||
      CompanyRole.viewer ||
      CompanyRole.driver => false,
    };
  }
}
