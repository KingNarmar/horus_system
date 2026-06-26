import '../../../company/domain/entities/company_role.dart';

abstract final class TripExpensesPermissionPolicy {
  static bool canViewTripExpenses(CompanyRole role) {
    return switch (role) {
      CompanyRole.owner ||
      CompanyRole.admin ||
      CompanyRole.operations ||
      CompanyRole.accountant ||
      CompanyRole.viewer => true,
      CompanyRole.driver => false,
    };
  }

  static bool canManageTripExpenses(CompanyRole role) {
    return switch (role) {
      CompanyRole.owner ||
      CompanyRole.admin ||
      CompanyRole.operations ||
      CompanyRole.accountant => true,
      CompanyRole.viewer || CompanyRole.driver => false,
    };
  }
}
