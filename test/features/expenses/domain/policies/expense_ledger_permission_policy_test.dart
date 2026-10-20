import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/expenses/domain/entities/expense_attribution.dart';
import 'package:horus_system/features/expenses/domain/policies/expense_ledger_permission_policy.dart';
import 'package:test/test.dart';

void main() {
  group('ExpenseLedgerPermissionPolicy financial access boundary', () {
    const financeRoles = <CompanyRole>{
      CompanyRole.owner,
      CompanyRole.admin,
      CompanyRole.accountant,
    };

    test('only finance roles may read ledger amounts', () {
      for (final role in CompanyRole.values) {
        expect(
          ExpenseLedgerPermissionPolicy.canView(role),
          financeRoles.contains(role),
          reason: 'Unexpected financial read access for $role',
        );
      }
    });

    test('only finance roles may manage trip-attributed expenses', () {
      for (final role in CompanyRole.values) {
        expect(
          ExpenseLedgerPermissionPolicy.canManageTripAttributed(role),
          financeRoles.contains(role),
          reason: 'Unexpected trip expense management for $role',
        );
        expect(
          ExpenseLedgerPermissionPolicy.canManage(
            role,
            attribution: const ExpenseAttribution(tripId: 'trip-1'),
          ),
          financeRoles.contains(role),
        );
      }
    });

    test('only finance roles may manage general expenses', () {
      for (final role in CompanyRole.values) {
        expect(
          ExpenseLedgerPermissionPolicy.canManage(
            role,
            attribution: const ExpenseAttribution(tractorHeadId: 'tractor-1'),
          ),
          financeRoles.contains(role),
        );
      }
    });
  });
}
