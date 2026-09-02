import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/entities/current_company_context.dart';
import 'package:horus_system/features/company/domain/failures/company_failure_codes.dart';
import 'package:horus_system/features/company/domain/repositories/company_timezone_repository.dart';
import 'package:horus_system/features/company/domain/usecases/update_company_business_timezone_usecase.dart';
import 'package:horus_system/features/company/domain/value_objects/company_timezone.dart';
import 'package:test/test.dart';

void main() {
  group('UpdateCompanyBusinessTimezoneUseCase', () {
    test('owner can update a normalized timezone within current company scope', () async {
      final repository = _FakeCompanyTimezoneRepository();
      final useCase = UpdateCompanyBusinessTimezoneUseCase(repository);

      final result = await useCase(
        UpdateCompanyBusinessTimezoneParams(
          currentCompanyContext: _context(CompanyRole.owner),
          businessTimezone: '  Europe/London  ',
        ),
      );

      expect(result.failureOrNull, isNull);
      expect(repository.lastCompanyId, 'company-1');
      expect(repository.lastTimezone?.value, 'Europe/London');
    });

    test('admin can update the timezone', () async {
      final repository = _FakeCompanyTimezoneRepository();
      final useCase = UpdateCompanyBusinessTimezoneUseCase(repository);

      final result = await useCase(
        UpdateCompanyBusinessTimezoneParams(
          currentCompanyContext: _context(CompanyRole.admin),
          businessTimezone: 'Asia/Dubai',
        ),
      );

      expect(result.failureOrNull, isNull);
      expect(repository.updateCallCount, 1);
    });

    test('non-management role is rejected before repository access', () async {
      final repository = _FakeCompanyTimezoneRepository();
      final useCase = UpdateCompanyBusinessTimezoneUseCase(repository);

      final result = await useCase(
        UpdateCompanyBusinessTimezoneParams(
          currentCompanyContext: _context(CompanyRole.operations),
          businessTimezone: 'Asia/Dubai',
        ),
      );

      expect(
        result.failureOrNull?.code,
        CompanyFailureCodes.permissionSettingsManagement,
      );
      expect(repository.updateCallCount, 0);
    });

    test('blank timezone is rejected before repository access', () async {
      final repository = _FakeCompanyTimezoneRepository();
      final useCase = UpdateCompanyBusinessTimezoneUseCase(repository);

      final result = await useCase(
        UpdateCompanyBusinessTimezoneParams(
          currentCompanyContext: _context(CompanyRole.owner),
          businessTimezone: '   ',
        ),
      );

      expect(
        result.failureOrNull?.code,
        CompanyFailureCodes.validationBusinessTimezoneRequired,
      );
      expect(repository.updateCallCount, 0);
    });
  });
}

CurrentCompanyContext _context(CompanyRole role) {
  return CurrentCompanyContext(
    company: const Company(
      id: 'company-1',
      name: 'Horus Transport',
      businessTimezone: 'Asia/Dubai',
    ),
    role: role,
  );
}

final class _FakeCompanyTimezoneRepository implements CompanyTimezoneRepository {
  int updateCallCount = 0;
  String? lastCompanyId;
  CompanyTimezone? lastTimezone;

  @override
  Future<Result<List<CompanyTimezone>>> getTimezoneOptions() async =>
      const Success<List<CompanyTimezone>>(<CompanyTimezone>[]);

  @override
  Future<Result<Company>> updateBusinessTimezone({
    required String companyId,
    required CompanyTimezone businessTimezone,
  }) async {
    updateCallCount += 1;
    lastCompanyId = companyId;
    lastTimezone = businessTimezone;
    return Success(
      Company(
        id: companyId,
        name: 'Horus Transport',
        businessTimezone: businessTimezone.value,
      ),
    );
  }
}
