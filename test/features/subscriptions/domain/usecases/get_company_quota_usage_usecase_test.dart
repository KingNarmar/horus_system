import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/entities/current_company_context.dart';
import 'package:horus_system/features/subscriptions/domain/entities/company_quota_snapshot.dart';
import 'package:horus_system/features/subscriptions/domain/failures/quota_failure_codes.dart';
import 'package:horus_system/features/subscriptions/domain/repositories/company_quota_repository.dart';
import 'package:horus_system/features/subscriptions/domain/usecases/get_company_quota_usage_usecase.dart';
import 'package:test/test.dart';

final class _Repository implements CompanyQuotaRepository {
  String? companyId;
  int calls = 0;

  @override
  Future<Result<CompanyQuotaSnapshot>> getUsage({
    required String companyId,
  }) async {
    calls++;
    this.companyId = companyId;
    return const FailureResult(
      ServerFailure(code: QuotaFailureCodes.unavailable),
    );
  }
}

CurrentCompanyContext _context(CompanyRole role, {String id = 'company-1'}) {
  return CurrentCompanyContext(
    company: Company(id: id, name: 'Test Company'),
    role: role,
  );
}

void main() {
  test('only owner and admin may request a server usage snapshot', () async {
    for (final role in [CompanyRole.owner, CompanyRole.admin]) {
      final repository = _Repository();
      final result = await GetCompanyQuotaUsageUseCase(repository)(
        GetCompanyQuotaUsageParams(
          currentCompanyContext: _context(role, id: ' company-1 '),
        ),
      );
      expect(result.failureOrNull?.code, QuotaFailureCodes.unavailable);
      expect(repository.companyId, 'company-1');
      expect(repository.calls, 1);
    }
  });

  test('other roles never access repository', () async {
    for (final role in [
      CompanyRole.operations,
      CompanyRole.accountant,
      CompanyRole.viewer,
      CompanyRole.driver,
    ]) {
      final repository = _Repository();
      final result = await GetCompanyQuotaUsageUseCase(repository)(
        GetCompanyQuotaUsageParams(currentCompanyContext: _context(role)),
      );
      expect(result.failureOrNull?.code, QuotaFailureCodes.permissionDenied);
      expect(result.failureOrNull, isA<PermissionFailure>());
      expect(repository.calls, 0);
    }
  });

  test('selected company id is mandatory', () async {
    final repository = _Repository();
    final result = await GetCompanyQuotaUsageUseCase(repository)(
      GetCompanyQuotaUsageParams(
        currentCompanyContext: _context(CompanyRole.owner, id: '   '),
      ),
    );
    expect(result.failureOrNull, isA<ValidationFailure>());
    expect(repository.calls, 0);
  });
}
