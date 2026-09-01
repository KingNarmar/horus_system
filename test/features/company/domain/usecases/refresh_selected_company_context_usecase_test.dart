import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/entities/current_company_context.dart';
import 'package:horus_system/features/company/domain/repositories/company_context_repository.dart';
import 'package:horus_system/features/company/domain/usecases/refresh_selected_company_context_usecase.dart';
import 'package:test/test.dart';

void main() {
  test(
    'reloads authoritative contexts before selecting requested company',
    () async {
      final repository = _FakeCompanyContextRepository();
      final useCase = RefreshSelectedCompanyContextUseCase(repository);

      final result = await useCase(
        const RefreshSelectedCompanyContextParams(companyId: ' company-2 '),
      );

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull?.companyId, 'company-2');
      expect(repository.operations, ['load', 'select:company-2']);
    },
  );

  test('does not select when authoritative reload fails', () async {
    final repository = _FakeCompanyContextRepository(
      loadResult: const FailureResult(UnexpectedFailure()),
    );
    final useCase = RefreshSelectedCompanyContextUseCase(repository);

    final result = await useCase(
      const RefreshSelectedCompanyContextParams(companyId: 'company-2'),
    );

    expect(result.isFailure, isTrue);
    expect(repository.operations, ['load']);
  });

  test('rejects blank company id before repository access', () async {
    final repository = _FakeCompanyContextRepository();
    final result = await RefreshSelectedCompanyContextUseCase(repository)(
      const RefreshSelectedCompanyContextParams(companyId: '   '),
    );

    expect(
      result.failureOrNull?.code,
      FailureCodes.validationCompanyContextRequired,
    );
    expect(repository.operations, isEmpty);
  });
}

class _FakeCompanyContextRepository implements CompanyContextRepository {
  final Result<List<CurrentCompanyContext>>? loadResult;
  final List<String> operations = [];
  final List<CurrentCompanyContext> contexts = const [
    CurrentCompanyContext(
      company: Company(id: 'company-1', name: 'One'),
      role: CompanyRole.owner,
    ),
    CurrentCompanyContext(
      company: Company(id: 'company-2', name: 'Two'),
      role: CompanyRole.admin,
    ),
  ];

  _FakeCompanyContextRepository({this.loadResult});

  @override
  Future<Result<void>> clearCurrentCompanyContext() async {
    return const Success(null);
  }

  @override
  Future<Result<CurrentCompanyContext?>> getCurrentCompanyContext() async {
    return const Success(null);
  }

  @override
  Future<Result<List<CurrentCompanyContext>>> loadUserCompanyContexts() async {
    operations.add('load');
    return loadResult ?? Success(contexts);
  }

  @override
  Future<Result<CurrentCompanyContext>> selectCompany(String companyId) async {
    operations.add('select:$companyId');
    for (final context in contexts) {
      if (context.companyId == companyId) return Success(context);
    }
    return const FailureResult(UnexpectedFailure());
  }
}
