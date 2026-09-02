import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/expense_types/domain/policies/expense_types_permission_policy.dart';
import 'package:test/test.dart';

void main() {
  group('ExpenseTypesPermissionPolicy', () {
    test('management is limited to owner, admin, and accountant', () {
      expect(
        ExpenseTypesPermissionPolicy.canManageExpenseTypes(CompanyRole.owner),
        isTrue,
      );
      expect(
        ExpenseTypesPermissionPolicy.canManageExpenseTypes(CompanyRole.admin),
        isTrue,
      );
      expect(
        ExpenseTypesPermissionPolicy.canManageExpenseTypes(
          CompanyRole.accountant,
        ),
        isTrue,
      );
      expect(
        ExpenseTypesPermissionPolicy.canManageExpenseTypes(
          CompanyRole.operations,
        ),
        isFalse,
      );
      expect(
        ExpenseTypesPermissionPolicy.canManageExpenseTypes(CompanyRole.viewer),
        isFalse,
      );
      expect(
        ExpenseTypesPermissionPolicy.canManageExpenseTypes(CompanyRole.driver),
        isFalse,
      );
    });

    test('active lookup is available to company app roles except driver', () {
      for (final role in [
        CompanyRole.owner,
        CompanyRole.admin,
        CompanyRole.operations,
        CompanyRole.accountant,
        CompanyRole.viewer,
      ]) {
        expect(
          ExpenseTypesPermissionPolicy.canViewActiveExpenseTypes(role),
          isTrue,
          reason: role.name,
        );
      }
      expect(
        ExpenseTypesPermissionPolicy.canViewActiveExpenseTypes(
          CompanyRole.driver,
        ),
        isFalse,
      );
    });
  });
}
