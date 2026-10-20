import '../../../company/domain/entities/company_role.dart';
import '../entities/expense_attribution.dart';

abstract final class ExpenseLedgerPermissionPolicy {
  static bool canView(CompanyRole role) {
    return switch (role) {
      CompanyRole.owner || CompanyRole.admin || CompanyRole.accountant => true,
      CompanyRole.operations ||
      CompanyRole.viewer ||
      CompanyRole.driver => false,
    };
  }

  static bool canManageTripAttributed(CompanyRole role) {
    return canView(role);
  }

  static bool canManage(
    CompanyRole role, {
    required ExpenseAttribution attribution,
  }) {
    if (attribution.isTripAttributed) {
      return canManageTripAttributed(role);
    }

    return canView(role);
  }
}
