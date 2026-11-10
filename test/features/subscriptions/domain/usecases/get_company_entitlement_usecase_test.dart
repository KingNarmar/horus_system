import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/entities/current_company_context.dart';
import 'package:horus_system/features/subscriptions/domain/entities/company_entitlement.dart';
import 'package:horus_system/features/subscriptions/domain/failures/entitlement_failure_codes.dart';
import 'package:horus_system/features/subscriptions/domain/repositories/company_entitlements_repository.dart';
import 'package:horus_system/features/subscriptions/domain/usecases/get_company_entitlement_usecase.dart';
import 'package:test/test.dart';

final class _Repository implements CompanyEntitlementsRepository {
  String? requestedCompanyId;
  int calls = 0;

  @override
  Future<Result<CompanyEntitlement>> getCurrent({
    required String companyId,
  }) async {
    calls += 1;
    requestedCompanyId = companyId;
    return const FailureResult(
      ServerFailure(code: EntitlementFailureCodes.unavailable),
    );
  }
}

CurrentCompanyContext _context(
  CompanyRole role, {
  String companyId = 'company-1',
}) {
  return CurrentCompanyContext(
    company: Company(id: companyId, name: 'Test Company'),
    role: role,
  );
}

void main() {
  test('owner and admin can request their selected entitlement', () async {
    for (final role in [CompanyRole.owner, CompanyRole.admin]) {
      final repository = _Repository();
      final result = await GetCompanyEntitlementUseCase(repository)(
        GetCompanyEntitlementParams(
          currentCompanyContext: _context(role, companyId: ' company-1 '),
        ),
      );

      expect(result.failureOrNull?.code, EntitlementFailureCodes.unavailable);
      expect(repository.requestedCompanyId, 'company-1');
      expect(repository.calls, 1);
    }
  });

  test('other company roles fail before repository access', () async {
    for (final role in [
      CompanyRole.operations,
      CompanyRole.accountant,
      CompanyRole.viewer,
      CompanyRole.driver,
    ]) {
      final repository = _Repository();
      final result = await GetCompanyEntitlementUseCase(repository)(
        GetCompanyEntitlementParams(currentCompanyContext: _context(role)),
      );

      expect(
        result.failureOrNull?.code,
        EntitlementFailureCodes.permissionDenied,
      );
      expect(repository.calls, 0);
    }
  });

  test('missing company id fails for authorized caller', () async {
    final repository = _Repository();
    final result = await GetCompanyEntitlementUseCase(repository)(
      GetCompanyEntitlementParams(
        currentCompanyContext: _context(CompanyRole.owner, companyId: '   '),
      ),
    );

    expect(result.failureOrNull, isA<ValidationFailure>());
    expect(repository.calls, 0);
  });
}
