import '../../../company/domain/entities/company_role.dart';

abstract final class CustomerStatementsPermissionPolicy {
  static bool canViewStatements(CompanyRole role) {
    return switch (role) {
      CompanyRole.owner || CompanyRole.admin || CompanyRole.accountant => true,
      CompanyRole.operations ||
      CompanyRole.viewer ||
      CompanyRole.driver => false,
    };
  }
}
