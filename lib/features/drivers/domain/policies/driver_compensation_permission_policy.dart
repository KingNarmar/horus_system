import '../../../company/domain/entities/company_role.dart';

abstract final class DriverCompensationPermissionPolicy {
  static bool canView(CompanyRole role) {
    return switch (role) {
      CompanyRole.owner || CompanyRole.admin || CompanyRole.accountant => true,
      CompanyRole.operations || CompanyRole.viewer || CompanyRole.driver => false,
    };
  }

  static bool canManage(CompanyRole role) {
    return switch (role) {
      CompanyRole.owner || CompanyRole.admin => true,
      CompanyRole.operations ||
      CompanyRole.accountant ||
      CompanyRole.viewer ||
      CompanyRole.driver => false,
    };
  }

  static bool canAccessContractDocument(CompanyRole role) {
    return canManage(role);
  }
}
