import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/expenses/domain/entities/expense_attribution.dart';
import 'package:horus_system/features/expenses/domain/policies/expense_ledger_permission_policy.dart';
import 'package:test/test.dart';

void main() {
  group('ExpenseLedgerPermissionPolicy', () {
    test('allows company members except drivers to view', () {
      for (final role in [
        CompanyRole.owner,
        CompanyRole.admin,
        CompanyRole.operations,
        CompanyRole.accountant,
        CompanyRole.viewer,
      ]) {
        expect(ExpenseLedgerPermissionPolicy.canView(role), isTrue);
      }

      expect(
        ExpenseLedgerPermissionPolicy.canView(CompanyRole.driver),
        isFalse,
      );
    });

    test('allows operations to manage trip expenses only', () {
      expect(
        ExpenseLedgerPermissionPolicy.canManage(
          CompanyRole.operations,
          attribution: const ExpenseAttribution(tripId: 'trip-1'),
        ),
        isTrue,
      );
      expect(
        ExpenseLedgerPermissionPolicy.canManage(
          CompanyRole.operations,
          attribution: const ExpenseAttribution(tractorHeadId: 'tractor-1'),
        ),
        isFalse,
      );
    });

    test(
      'allows owner admin accountant to manage all expense attributions',
      () {
        for (final role in [
          CompanyRole.owner,
          CompanyRole.admin,
          CompanyRole.accountant,
        ]) {
          expect(
            ExpenseLedgerPermissionPolicy.canManage(
              role,
              attribution: const ExpenseAttribution(),
            ),
            isTrue,
          );
          expect(
            ExpenseLedgerPermissionPolicy.canManage(
              role,
              attribution: const ExpenseAttribution(tripId: 'trip-1'),
            ),
            isTrue,
          );
        }
      },
    );

    test('denies viewer and driver mutation access', () {
      for (final role in [CompanyRole.viewer, CompanyRole.driver]) {
        expect(
          ExpenseLedgerPermissionPolicy.canManage(
            role,
            attribution: const ExpenseAttribution(tripId: 'trip-1'),
          ),
          isFalse,
        );
      }
    });
  });
}
