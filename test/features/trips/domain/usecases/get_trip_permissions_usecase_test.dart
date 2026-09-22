import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/entities/current_company_context.dart';
import 'package:horus_system/features/trips/domain/usecases/get_trip_permissions_usecase.dart';
import 'package:test/test.dart';

void main() {
  test('GetTripPermissionsUseCase mirrors the Trips role matrix', () async {
    const useCase = GetTripPermissionsUseCase();

    final expected = <CompanyRole, List<bool>>{
      CompanyRole.owner: [true, true, true, true],
      CompanyRole.admin: [true, true, true, true],
      CompanyRole.operations: [true, true, true, false],
      CompanyRole.accountant: [false, false, false, true],
      CompanyRole.viewer: [false, false, false, false],
      CompanyRole.driver: [false, false, false, false],
    };

    for (final entry in expected.entries) {
      final result = await useCase(
        GetTripPermissionsParams(currentCompanyContext: _context(entry.key)),
      );
      final permissions = result.dataOrNull;

      expect(permissions, isNotNull);
      expect(
        [
          permissions!.canManageTrips,
          permissions.canUpdateTripStatus,
          permissions.canManageTripDocuments,
          permissions.canViewTripFinancials,
        ],
        entry.value,
        reason: 'Unexpected Trip permissions for ${entry.key}',
      );
    }
  });
}

CurrentCompanyContext _context(CompanyRole role) {
  return CurrentCompanyContext(
    company: const Company(id: 'company-1', name: 'Company'),
    role: role,
  );
}
