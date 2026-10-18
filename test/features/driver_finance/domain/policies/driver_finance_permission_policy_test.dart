import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/driver_finance/domain/policies/driver_finance_permission_policy.dart';
import 'package:test/test.dart';

void main() {
  test('financial movement reads require finance role', () {
    const financeRoles = <CompanyRole>{
      CompanyRole.owner,
      CompanyRole.admin,
      CompanyRole.accountant,
    };
    for (final role in CompanyRole.values) {
      expect(
        DriverFinancePermissionPolicy.canViewDriverFinance(role),
        financeRoles.contains(role),
      );
    }
  });
}
