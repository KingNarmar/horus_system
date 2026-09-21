import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/entities/current_company_context.dart';
import 'package:horus_system/features/routes/domain/usecases/can_manage_routes_usecase.dart';
import 'package:test/test.dart';

void main() {
  test('CanManageRoutesUseCase mirrors the established role matrix', () async {
    const useCase = CanManageRoutesUseCase();
    const allowed = <CompanyRole>{CompanyRole.owner, CompanyRole.admin, CompanyRole.operations};

    for (final role in CompanyRole.values) {
      final result = await useCase(
        CanManageRoutesParams(currentCompanyContext: _context(role)),
      );

      expect(
        result.dataOrNull,
        allowed.contains(role),
        reason: 'Unexpected canManageRoutes result for $role',
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
