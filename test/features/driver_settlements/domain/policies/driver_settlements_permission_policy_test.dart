import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/driver_settlements/domain/policies/driver_settlements_permission_policy.dart';
import 'package:test/test.dart';

void main() {
  group('DriverSettlementsPermissionPolicy', () {
    test('allows only finance-sensitive roles to view settlements', () {
      expect(
        DriverSettlementsPermissionPolicy.canViewDriverSettlements(
          CompanyRole.owner,
        ),
        isTrue,
      );
      expect(
        DriverSettlementsPermissionPolicy.canViewDriverSettlements(
          CompanyRole.admin,
        ),
        isTrue,
      );
      expect(
        DriverSettlementsPermissionPolicy.canViewDriverSettlements(
          CompanyRole.accountant,
        ),
        isTrue,
      );
      expect(
        DriverSettlementsPermissionPolicy.canViewDriverSettlements(
          CompanyRole.operations,
        ),
        isFalse,
      );
      expect(
        DriverSettlementsPermissionPolicy.canViewDriverSettlements(
          CompanyRole.viewer,
        ),
        isFalse,
      );
      expect(
        DriverSettlementsPermissionPolicy.canViewDriverSettlements(
          CompanyRole.driver,
        ),
        isFalse,
      );
    });

    test('uses the same restricted roles for management actions', () {
      expect(
        DriverSettlementsPermissionPolicy.canManageDriverSettlements(
          CompanyRole.accountant,
        ),
        isTrue,
      );
      expect(
        DriverSettlementsPermissionPolicy.canFinalizeDriverSettlements(
          CompanyRole.accountant,
        ),
        isTrue,
      );
      expect(
        DriverSettlementsPermissionPolicy.canVoidDriverSettlements(
          CompanyRole.accountant,
        ),
        isTrue,
      );
      expect(
        DriverSettlementsPermissionPolicy.canManageDriverSettlements(
          CompanyRole.operations,
        ),
        isFalse,
      );
    });
  });
}
