import '../../../company/domain/entities/company_role.dart';

abstract final class ExpenseTypesPermissionPolicy {
  static bool canViewExpenseTypes(CompanyRole role) {
    return switch (role) {
      CompanyRole.owner ||
      CompanyRole.admin ||
      CompanyRole.operations ||
      CompanyRole.accountant ||
      CompanyRole.viewer => true,
      CompanyRole.driver => false,
    };
  }

  static bool canViewActiveExpenseTypes(CompanyRole role) {
    return canViewExpenseTypes(role);
  }

  static bool canManageExpenseTypes(CompanyRole role) {
    return switch (role) {
      CompanyRole.owner || CompanyRole.admin || CompanyRole.accountant => true,
      CompanyRole.operations ||
      CompanyRole.viewer ||
      CompanyRole.driver => false,
    };
  }
}
