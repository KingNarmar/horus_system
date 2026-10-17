import '../../../company/domain/entities/company_role.dart';

abstract final class TripExpensesPermissionPolicy {
  static bool canViewTripExpenses(CompanyRole role) {
    return switch (role) {
      CompanyRole.owner || CompanyRole.admin || CompanyRole.accountant => true,
      CompanyRole.operations ||
      CompanyRole.viewer ||
      CompanyRole.driver => false,
    };
  }

  static bool canManageTripExpenses(CompanyRole role) {
    return canViewTripExpenses(role);
  }
}
