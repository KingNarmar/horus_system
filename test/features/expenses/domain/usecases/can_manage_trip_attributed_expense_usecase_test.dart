import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/entities/current_company_context.dart';
import 'package:horus_system/features/expenses/domain/usecases/can_manage_trip_attributed_expense_usecase.dart';
import 'package:test/test.dart';

void main() {
  test('CanManageTripAttributedExpenseUseCase mirrors the established role matrix', () async {
    const useCase = CanManageTripAttributedExpenseUseCase();
    const allowed = <CompanyRole>{CompanyRole.owner, CompanyRole.admin, CompanyRole.operations, CompanyRole.accountant};

    for (final role in CompanyRole.values) {
      final result = await useCase(
        CanManageTripAttributedExpenseParams(currentCompanyContext: _context(role)),
      );

      expect(
        result.dataOrNull,
        allowed.contains(role),
        reason: 'Unexpected canManageTripAttributed result for $role',
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
