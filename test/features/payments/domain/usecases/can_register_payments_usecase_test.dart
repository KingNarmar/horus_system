import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/entities/current_company_context.dart';
import 'package:horus_system/features/payments/domain/usecases/can_register_payments_usecase.dart';
import 'package:test/test.dart';

void main() {
  test(
    'CanRegisterPaymentsUseCase mirrors the established role matrix',
    () async {
      const useCase = CanRegisterPaymentsUseCase();
      const allowed = <CompanyRole>{
        CompanyRole.owner,
        CompanyRole.admin,
        CompanyRole.accountant,
      };

      for (final role in CompanyRole.values) {
        final result = await useCase(
          CanRegisterPaymentsParams(currentCompanyContext: _context(role)),
        );

        expect(
          result.dataOrNull,
          allowed.contains(role),
          reason: 'Unexpected canRegisterPayments result for $role',
        );
      }
    },
  );
}

CurrentCompanyContext _context(CompanyRole role) {
  return CurrentCompanyContext(
    company: const Company(id: 'company-1', name: 'Company'),
    role: role,
  );
}
