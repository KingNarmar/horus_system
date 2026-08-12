import '../../../company/domain/entities/company_role.dart';

abstract final class CustomerStatementsPermissionPolicy {
  static bool canViewStatements(CompanyRole role) {
    return switch (role) {
      CompanyRole.owner ||
      CompanyRole.admin ||
      CompanyRole.operations ||
      CompanyRole.accountant ||
      CompanyRole.viewer => true,
      CompanyRole.driver => false,
    };
  }
}
