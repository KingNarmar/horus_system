import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/fleet/domain/policies/fleet_permission_policy.dart';
import 'package:test/test.dart';

void main() {
  group('FleetPermissionPolicy', () {
    test('preserves view permission matrix', () {
      const expected = {
        CompanyRole.owner: true,
        CompanyRole.admin: true,
        CompanyRole.operations: true,
        CompanyRole.accountant: true,
        CompanyRole.viewer: true,
        CompanyRole.driver: false,
      };

      for (final role in CompanyRole.values) {
        expect(
          FleetPermissionPolicy.canViewFleet(role),
          expected[role],
          reason: 'Unexpected Fleet view permission for $role',
        );
      }
    });

    test('preserves manage permission matrix', () {
      const expected = {
        CompanyRole.owner: true,
        CompanyRole.admin: true,
        CompanyRole.operations: true,
        CompanyRole.accountant: false,
        CompanyRole.viewer: false,
        CompanyRole.driver: false,
      };

      for (final role in CompanyRole.values) {
        expect(
          FleetPermissionPolicy.canManageFleet(role),
          expected[role],
          reason: 'Unexpected Fleet manage permission for $role',
        );
      }
    });
  });
}
