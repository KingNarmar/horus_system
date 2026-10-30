import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/failures/company_failure_codes.dart';
import 'package:horus_system/features/company/domain/repositories/company_repository.dart';
import 'package:horus_system/features/company/domain/usecases/create_company_usecase.dart';
import 'package:horus_system/features/company/domain/value_objects/company_timezone.dart';
import 'package:test/test.dart';

void main() {
  group('CreateCompanyUseCase timezone support', () {
    test(
      'normalizes company and timezone values before repository call',
      () async {
        final repository = _FakeCompanyRepository();
        final useCase = CreateCompanyUseCase(repository);

        final result = await useCase(
          const CreateCompanyParams(
            name: '  Horus Transport  ',
            businessTimezone: '  Asia/Dubai  ',
            businessType: '  Heavy Transport  ',
          ),
        );

        expect(result.failureOrNull, isNull);
        expect(repository.lastName, 'Horus Transport');
        expect(repository.lastTimezone?.value, 'Asia/Dubai');
        expect(repository.lastBusinessType, 'Heavy Transport');
      },
    );

    test(
      'rejects a missing business timezone before repository access',
      () async {
        final repository = _FakeCompanyRepository();
        final useCase = CreateCompanyUseCase(repository);

        final result = await useCase(
          const CreateCompanyParams(
            name: 'Horus Transport',
            businessTimezone: '   ',
          ),
        );

        expect(
          result.failureOrNull?.code,
          CompanyFailureCodes.validationBusinessTimezoneRequired,
        );
        expect(repository.createCallCount, 0);
      },
    );

    test(
      'rejects a malformed business timezone before repository access',
      () async {
        final repository = _FakeCompanyRepository();
        final useCase = CreateCompanyUseCase(repository);

        final result = await useCase(
          const CreateCompanyParams(
            name: 'Horus Transport',
            businessTimezone: 'Asia /Dubai',
          ),
        );

        expect(
          result.failureOrNull?.code,
          CompanyFailureCodes.validationBusinessTimezoneInvalid,
        );
        expect(repository.createCallCount, 0);
      },
    );
  });
}

final class _FakeCompanyRepository implements CompanyRepository {
  int createCallCount = 0;
  String? lastName;
  CompanyTimezone? lastTimezone;
  String? lastBusinessType;

  @override
  Future<Result<Company>> createCompany({
    required String name,
    required CompanyTimezone businessTimezone,
    String? businessType,
    String? phone,
    String? email,
    String? country,
    String? city,
  }) async {
    createCallCount += 1;
    lastName = name;
    lastTimezone = businessTimezone;
    lastBusinessType = businessType;
    return Success(
      Company(
        id: 'company-1',
        name: name,
        businessTimezone: businessTimezone.value,
      ),
    );
  }

  @override
  Future<Result<List<Company>>> getMyCompanies() async =>
      const Success<List<Company>>(<Company>[]);
}
