import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/customer_statements/domain/policies/customer_statements_permission_policy.dart';
import 'package:test/test.dart';

void main() {
  test('allows all statement read roles except driver', () {
    for (final role in CompanyRole.values) {
      expect(
        CustomerStatementsPermissionPolicy.canViewStatements(role),
        role != CompanyRole.driver,
        reason: 'Unexpected customer statement access for ${role.name}.',
      );
    }
  });
}
