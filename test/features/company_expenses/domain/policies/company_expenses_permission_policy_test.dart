import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company_expenses/domain/policies/company_expenses_permission_policy.dart';
import 'package:test/test.dart';

void main() {
  test('company expenses are readable only by finance roles', () {
    const allowed = <CompanyRole>{
      CompanyRole.owner,
      CompanyRole.admin,
      CompanyRole.accountant,
    };
    for (final role in CompanyRole.values) {
      expect(
        CompanyExpensesPermissionPolicy.canViewCompanyExpenses(role),
        allowed.contains(role),
      );
      expect(
        CompanyExpensesPermissionPolicy.canManageCompanyExpenses(role),
        allowed.contains(role),
      );
    }
  });
}
