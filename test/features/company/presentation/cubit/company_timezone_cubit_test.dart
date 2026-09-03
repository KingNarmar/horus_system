import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/entities/current_company_context.dart';
import 'package:horus_system/features/company/domain/failures/company_failure_codes.dart';
import 'package:horus_system/features/company/domain/repositories/company_timezone_repository.dart';
import 'package:horus_system/features/company/domain/usecases/get_company_timezone_options_usecase.dart';
import 'package:horus_system/features/company/domain/usecases/update_company_business_timezone_usecase.dart';
import 'package:horus_system/features/company/domain/value_objects/company_timezone.dart';
import 'package:horus_system/features/company/presentation/cubit/company_timezone_cubit.dart';
import 'package:horus_system/features/company/presentation/cubit/company_timezone_state.dart';

void main() {
  test('loadOptions exposes the company timezone catalog', () async {
    final repository = _FakeCompanyTimezoneRepository();
    final cubit = _buildCubit(repository);
    addTearDown(cubit.close);

    await cubit.loadOptions();

    expect(cubit.state, isA<CompanyTimezoneReady>());
    expect(cubit.state.options.map((option) => option.value).toList(), [
      'Asia/Dubai',
      'Europe/London',
    ]);
  });

  test('owner update keeps company scope and exposes saved company', () async {
    final repository = _FakeCompanyTimezoneRepository();
    final cubit = _buildCubit(repository);
    addTearDown(cubit.close);
    await cubit.loadOptions();

    await cubit.updateBusinessTimezone(
      currentCompanyContext: _context(CompanyRole.owner),
      businessTimezone: 'Europe/London',
    );

    expect(cubit.state, isA<CompanyTimezoneSaved>());
    expect(repository.lastCompanyId, 'company-1');
    expect(repository.lastTimezone?.value, 'Europe/London');
    expect(
      (cubit.state as CompanyTimezoneSaved).company.businessTimezone,
      'Europe/London',
    );
  });

  test('non-management role exposes typed permission failure', () async {
    final repository = _FakeCompanyTimezoneRepository();
    final cubit = _buildCubit(repository);
    addTearDown(cubit.close);
    await cubit.loadOptions();

    await cubit.updateBusinessTimezone(
      currentCompanyContext: _context(CompanyRole.viewer),
      businessTimezone: 'Europe/London',
    );

    expect(cubit.state, isA<CompanyTimezoneFailure>());
    expect(
      (cubit.state as CompanyTimezoneFailure).failure.code,
      CompanyFailureCodes.permissionSettingsManagement,
    );
    expect(repository.updateCallCount, 0);
  });
}

CompanyTimezoneCubit _buildCubit(CompanyTimezoneRepository repository) {
  return CompanyTimezoneCubit(
    getOptionsUseCase: GetCompanyTimezoneOptionsUseCase(repository),
    updateTimezoneUseCase: UpdateCompanyBusinessTimezoneUseCase(repository),
  );
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

final class _FakeCompanyTimezoneRepository
    implements CompanyTimezoneRepository {
  int updateCallCount = 0;
  String? lastCompanyId;
  CompanyTimezone? lastTimezone;

  @override
  Future<Result<List<CompanyTimezone>>> getTimezoneOptions() async => Success([
    CompanyTimezone.tryParse('Asia/Dubai')!,
    CompanyTimezone.tryParse('Europe/London')!,
  ]);

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
