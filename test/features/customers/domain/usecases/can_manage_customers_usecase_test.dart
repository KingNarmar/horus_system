import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/entities/current_company_context.dart';
import 'package:horus_system/features/customers/domain/policies/customers_permission_policy.dart';
import 'package:horus_system/features/customers/domain/usecases/can_manage_customers_usecase.dart';
import 'package:test/test.dart';

void main() {
  test('CanManageCustomersUseCase mirrors the established role matrix', () async {
    const useCase = CanManageCustomersUseCase();
    const allowed = <CompanyRole>{CompanyRole.owner, CompanyRole.admin, CompanyRole.operations};

    for (final role in CompanyRole.values) {
      final result = await useCase(
        CanManageCustomersParams(currentCompanyContext: _context(role)),
      );

      expect(
        result.dataOrNull,
        allowed.contains(role),
        reason: 'Unexpected canManageCustomers result for $role',
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
