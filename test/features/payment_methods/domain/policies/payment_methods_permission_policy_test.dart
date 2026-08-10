import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/payment_methods/domain/policies/payment_methods_permission_policy.dart';
import 'package:test/test.dart';

void main() {
  group('PaymentMethodsPermissionPolicy', () {
    test('owner, admin, and accountant can manage payment methods', () {
      for (final role in [
        CompanyRole.owner,
        CompanyRole.admin,
        CompanyRole.accountant,
      ]) {
        expect(
          PaymentMethodsPermissionPolicy.canManagePaymentMethods(role),
          isTrue,
        );
      }
    });

    test('operations, viewer, and driver cannot manage payment methods', () {
      for (final role in [
        CompanyRole.operations,
        CompanyRole.viewer,
        CompanyRole.driver,
      ]) {
        expect(
          PaymentMethodsPermissionPolicy.canManagePaymentMethods(role),
          isFalse,
        );
      }
    });

    test('company business roles can view while driver cannot', () {
      for (final role in [
        CompanyRole.owner,
        CompanyRole.admin,
        CompanyRole.operations,
        CompanyRole.accountant,
        CompanyRole.viewer,
      ]) {
        expect(
          PaymentMethodsPermissionPolicy.canViewPaymentMethods(role),
          isTrue,
        );
      }

      expect(
        PaymentMethodsPermissionPolicy.canViewPaymentMethods(
          CompanyRole.driver,
        ),
        isFalse,
      );
    });
  });
}
