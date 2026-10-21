import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/core/realtime/domain/entities/company_data_change.dart';
import 'package:horus_system/core/realtime/domain/repositories/company_data_changes_repository.dart';
import 'package:horus_system/core/realtime/domain/usecases/watch_company_data_changes_usecase.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:test/test.dart';

void main() {
  test('rejects blank company without opening a stream', () async {
    final repository = _FakeChangesRepository();
    final useCase = WatchCompanyDataChangesUseCase(repository);
    final result = await useCase(
      const WatchCompanyDataChangesParams(companyId: '   '),
    ).single;
    expect(
      result.failureOrNull?.code,
      FailureCodes.validationCompanyIdRequired,
    );
    expect(repository.watchCount, 0);
  });

  test('trims company and forwards typed change', () async {
    final repository = _FakeChangesRepository();
    final useCase = WatchCompanyDataChangesUseCase(repository);
    final result = await useCase(
      const WatchCompanyDataChangesParams(companyId: '  company-1  '),
    ).single;
    expect(repository.lastCompanyId, 'company-1');
    expect(result.dataOrNull?.companyId, 'company-1');
    expect(result.dataOrNull?.resource, CompanyDataResource.customers);
  });

  test(
    'passes requested finance resources without coupling to roles',
    () async {
      final repository = _FakeChangesRepository();
      final useCase = WatchCompanyDataChangesUseCase(repository);
      await useCase(
        const WatchCompanyDataChangesParams(
          companyId: 'company-1',
          additionalResources: {CompanyDataResource.tripExpenses},
        ),
      ).single;
      expect(repository.lastAdditionalResources, {
        CompanyDataResource.tripExpenses,
      });
    },
  );
}

final class _FakeChangesRepository implements CompanyDataChangesRepository {
  int watchCount = 0;
  String? lastCompanyId;
  Set<CompanyDataResource> lastAdditionalResources = const {};

  @override
  Stream<Result<CompanyDataChange>> watchChanges({
    required String companyId,
    Set<CompanyDataResource> additionalResources = const {},
  }) {
    lastAdditionalResources = additionalResources;
    watchCount++;
    lastCompanyId = companyId;
    return Stream.value(
      Success(
        CompanyDataChange(
          companyId: companyId,
          resource: CompanyDataResource.customers,
        ),
      ),
    );
  }
}
