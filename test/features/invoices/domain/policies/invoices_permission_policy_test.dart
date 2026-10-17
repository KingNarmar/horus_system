import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/invoices/domain/policies/invoices_permission_policy.dart';
import 'package:test/test.dart';

void main() {
  test('invoice monetary details are visible only to finance roles', () {
    const financeRoles = <CompanyRole>{
      CompanyRole.owner,
      CompanyRole.admin,
      CompanyRole.accountant,
    };
    for (final role in CompanyRole.values) {
      expect(
        InvoicesPermissionPolicy.canViewInvoices(role),
        financeRoles.contains(role),
        reason: 'Unexpected invoice read access for $role',
      );
    }
  });
}
