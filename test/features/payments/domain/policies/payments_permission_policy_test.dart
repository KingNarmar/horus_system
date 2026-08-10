import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/payments/domain/policies/payments_permission_policy.dart';
import 'package:test/test.dart';

void main() {
  test('payment view permission follows approved role matrix', () {
    for (final role in [
      CompanyRole.owner,
      CompanyRole.admin,
      CompanyRole.operations,
      CompanyRole.accountant,
      CompanyRole.viewer,
    ]) {
      expect(PaymentsPermissionPolicy.canViewPayments(role), isTrue);
    }
    expect(
      PaymentsPermissionPolicy.canViewPayments(CompanyRole.driver),
      isFalse,
    );
  });

  test('only owner admin and accountant can register payments', () {
    for (final role in [
      CompanyRole.owner,
      CompanyRole.admin,
      CompanyRole.accountant,
    ]) {
      expect(PaymentsPermissionPolicy.canRegisterPayments(role), isTrue);
    }

    for (final role in [
      CompanyRole.operations,
      CompanyRole.viewer,
      CompanyRole.driver,
    ]) {
      expect(PaymentsPermissionPolicy.canRegisterPayments(role), isFalse);
    }
  });
}
