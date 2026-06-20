import '../../../company/domain/entities/company_role.dart';

abstract final class TripsPermissionPolicy {
  static bool canViewTrips(CompanyRole role) {
    return switch (role) {
      CompanyRole.owner ||
      CompanyRole.admin ||
      CompanyRole.operations ||
      CompanyRole.accountant ||
      CompanyRole.viewer => true,
      CompanyRole.driver => false,
    };
  }

  static bool canManageTrips(CompanyRole role) {
    return switch (role) {
      CompanyRole.owner || CompanyRole.admin || CompanyRole.operations => true,
      CompanyRole.accountant ||
      CompanyRole.viewer ||
      CompanyRole.driver => false,
    };
  }

  static bool canUpdateTripStatus(CompanyRole role) {
    return switch (role) {
      CompanyRole.owner || CompanyRole.admin || CompanyRole.operations => true,
      CompanyRole.accountant ||
      CompanyRole.viewer ||
      CompanyRole.driver => false,
    };
  }

  static bool canViewTripFinancials(CompanyRole role) {
    return switch (role) {
      CompanyRole.owner || CompanyRole.admin || CompanyRole.accountant => true,
      CompanyRole.operations ||
      CompanyRole.viewer ||
      CompanyRole.driver => false,
    };
  }
}
