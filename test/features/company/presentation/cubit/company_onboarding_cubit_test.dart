import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/repositories/company_repository.dart';
import 'package:horus_system/features/company/domain/usecases/create_company_usecase.dart';
import 'package:horus_system/features/company/domain/usecases/get_my_companies_usecase.dart';
import 'package:horus_system/features/company/domain/value_objects/company_timezone.dart';
import 'package:horus_system/features/company/presentation/cubit/company_onboarding_cubit.dart';
import 'package:horus_system/features/company/presentation/cubit/company_onboarding_state.dart';
import 'package:test/test.dart';

void main() {
  test('create company exposes a distinct created state', () async {
    final repository = _FakeCompanyRepository(
      createResult: const Success(_company),
    );
    final cubit = _createCubit(repository);
    addTearDown(cubit.close);

    final states = cubit.stream.take(2).toList();
    await cubit.createCompany(
      name: 'Horus Transport',
      businessTimezone: 'Asia/Dubai',
    );

    final emitted = await states;
    expect(emitted[0], isA<CompanyOnboardingLoading>());
    final created = emitted[1] as CompanyOnboardingCreated;
    expect(created.company.id, _company.id);
  });

  test('loading existing companies keeps loaded semantics', () async {
    final repository = _FakeCompanyRepository(
      companiesResult: const Success([_company]),
    );
    final cubit = _createCubit(repository);
    addTearDown(cubit.close);

    final states = cubit.stream.take(2).toList();
    await cubit.loadMyCompanies();

    final emitted = await states;
    expect(emitted[0], isA<CompanyOnboardingLoading>());
    final loaded = emitted[1] as CompanyOnboardingLoaded;
    expect(loaded.activeCompany.id, _company.id);
  });
}

const _company = Company(
  id: 'company-1',
  name: 'Horus Transport',
  businessTimezone: 'Asia/Dubai',
);

CompanyOnboardingCubit _createCubit(_FakeCompanyRepository repository) {
  return CompanyOnboardingCubit(
    createCompanyUseCase: CreateCompanyUseCase(repository),
    getMyCompaniesUseCase: GetMyCompaniesUseCase(repository),
  );
}

final class _FakeCompanyRepository implements CompanyRepository {
  final Result<Company> createResult;
  final Result<List<Company>> companiesResult;

  _FakeCompanyRepository({
    Result<Company>? createResult,
    Result<List<Company>>? companiesResult,
  }) : createResult = createResult ?? const Success(_company),
       companiesResult =
           companiesResult ?? const Success<List<Company>>(<Company>[]);

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
    return createResult;
  }

  @override
  Future<Result<List<Company>>> getMyCompanies() async {
    return companiesResult;
  }
}
