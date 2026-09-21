import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/entities/current_company_context.dart';
import 'package:horus_system/features/company_expenses/domain/policies/company_expenses_permission_policy.dart';
import 'package:horus_system/features/company_expenses/domain/usecases/can_manage_company_expenses_usecase.dart';
import 'package:test/test.dart';

void main() {
  test('CanManageCompanyExpensesUseCase mirrors the established role matrix', () async {
    const useCase = CanManageCompanyExpensesUseCase();
    const allowed = <CompanyRole>{CompanyRole.owner, CompanyRole.admin, CompanyRole.accountant};

    for (final role in CompanyRole.values) {
      final result = await useCase(
        CanManageCompanyExpensesParams(currentCompanyContext: _context(role)),
      );

      expect(
        result.dataOrNull,
        allowed.contains(role),
        reason: 'Unexpected canManageCompanyExpenses result for $role',
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
