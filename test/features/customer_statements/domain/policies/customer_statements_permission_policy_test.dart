import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/customer_statements/domain/policies/customer_statements_permission_policy.dart';
import 'package:test/test.dart';

void main() {
  test('restricts customer invoice and payment statements to finance roles', () {
    const financeRoles = <CompanyRole>{
      CompanyRole.owner,
      CompanyRole.admin,
      CompanyRole.accountant,
    };
    for (final role in CompanyRole.values) {
      expect(
        CustomerStatementsPermissionPolicy.canViewStatements(role),
        financeRoles.contains(role),
        reason: 'Unexpected customer statement access for ${role.name}.',
      );
    }
  });
}
