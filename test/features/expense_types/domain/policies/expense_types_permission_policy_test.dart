import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/expense_types/domain/policies/expense_types_permission_policy.dart';
import 'package:test/test.dart';

void main() {
  group('ExpenseTypesPermissionPolicy', () {
    test('catalog view is available to company app roles except driver', () {
      for (final role in [
        CompanyRole.owner,
        CompanyRole.admin,
        CompanyRole.operations,
        CompanyRole.accountant,
        CompanyRole.viewer,
      ]) {
        expect(
          ExpenseTypesPermissionPolicy.canViewExpenseTypes(role),
          isTrue,
          reason: role.name,
        );
      }
      expect(
        ExpenseTypesPermissionPolicy.canViewExpenseTypes(CompanyRole.driver),
        isFalse,
      );
    });

    test('active catalog view follows the same read permission', () {
      for (final role in CompanyRole.values) {
        expect(
          ExpenseTypesPermissionPolicy.canViewActiveExpenseTypes(role),
          ExpenseTypesPermissionPolicy.canViewExpenseTypes(role),
          reason: role.name,
        );
      }
    });
  });
}
