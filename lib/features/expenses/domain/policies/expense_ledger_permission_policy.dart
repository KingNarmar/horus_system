import '../../../company/domain/entities/company_role.dart';
import '../entities/expense_attribution.dart';

abstract final class ExpenseLedgerPermissionPolicy {
  static bool canView(CompanyRole role) {
    return switch (role) {
      CompanyRole.owner ||
      CompanyRole.admin ||
      CompanyRole.operations ||
      CompanyRole.accountant ||
      CompanyRole.viewer => true,
      CompanyRole.driver => false,
    };
  }

  static bool canManage(
    CompanyRole role, {
    required ExpenseAttribution attribution,
  }) {
    if (attribution.isTripAttributed) {
      return switch (role) {
        CompanyRole.owner ||
        CompanyRole.admin ||
        CompanyRole.operations ||
        CompanyRole.accountant => true,
        CompanyRole.viewer || CompanyRole.driver => false,
      };
    }

    return switch (role) {
      CompanyRole.owner || CompanyRole.admin || CompanyRole.accountant => true,
      CompanyRole.operations ||
      CompanyRole.viewer ||
      CompanyRole.driver => false,
    };
  }
}
