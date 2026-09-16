import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/drivers/domain/policies/driver_compensation_permission_policy.dart';
import 'package:test/test.dart';

void main() {
  group('DriverCompensationPermissionPolicy', () {
    test('owner and admin can manage compensation', () {
      expect(
        DriverCompensationPermissionPolicy.canManage(CompanyRole.owner),
        isTrue,
      );
      expect(
        DriverCompensationPermissionPolicy.canManage(CompanyRole.admin),
        isTrue,
      );
    });

    test('accountant can view but cannot manage compensation', () {
      expect(
        DriverCompensationPermissionPolicy.canView(CompanyRole.accountant),
        isTrue,
      );
      expect(
        DriverCompensationPermissionPolicy.canManage(CompanyRole.accountant),
        isFalse,
      );
      expect(
        DriverCompensationPermissionPolicy.canAccessContractDocument(
          CompanyRole.accountant,
        ),
        isFalse,
      );
    });

    test('operations viewer and driver cannot view compensation', () {
      for (final role in [
        CompanyRole.operations,
        CompanyRole.viewer,
        CompanyRole.driver,
      ]) {
        expect(DriverCompensationPermissionPolicy.canView(role), isFalse);
      }
    });
  });
}
