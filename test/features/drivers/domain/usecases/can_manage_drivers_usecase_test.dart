import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/entities/current_company_context.dart';
import 'package:horus_system/features/drivers/domain/policies/drivers_permission_policy.dart';
import 'package:horus_system/features/drivers/domain/usecases/can_manage_drivers_usecase.dart';
import 'package:test/test.dart';

void main() {
  test('CanManageDriversUseCase mirrors the established role matrix', () async {
    const useCase = CanManageDriversUseCase();
    const allowed = <CompanyRole>{CompanyRole.owner, CompanyRole.admin, CompanyRole.operations};

    for (final role in CompanyRole.values) {
      final result = await useCase(
        CanManageDriversParams(currentCompanyContext: _context(role)),
      );

      expect(
        result.dataOrNull,
        allowed.contains(role),
        reason: 'Unexpected canManageDrivers result for $role',
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
