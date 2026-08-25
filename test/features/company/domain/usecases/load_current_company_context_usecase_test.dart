import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/core/usecases/usecase.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/entities/current_company_context.dart';
import 'package:horus_system/features/company/domain/failures/company_failure_codes.dart';
import 'package:horus_system/features/company/domain/repositories/company_context_repository.dart';
import 'package:horus_system/features/company/domain/usecases/load_current_company_context_usecase.dart';
import 'package:test/test.dart';

void main() {
  group('LoadCurrentCompanyContextUseCase', () {
    test('clears context and returns null when no contexts exist', () async {
      final repository = _FakeCompanyContextRepository();

      final result = await LoadCurrentCompanyContextUseCase(repository)(
        const NoParams(),
      );

      expect(result.dataOrNull, isNull);
      expect(result.failureOrNull, isNull);
      expect(repository.clearCalls, 1);
      expect(repository.selectCalls, 0);
    });

    test('selects first loaded context', () async {
      const first = _firstContext;
      const second = _secondContext;
      final repository = _FakeCompanyContextRepository(
        loadResult: const Success([first, second]),
        selectResult: const Success(first),
      );

      final result = await LoadCurrentCompanyContextUseCase(repository)(
        const NoParams(),
      );

      expect(result.dataOrNull, same(first));
      expect(repository.selectedCompanyId, 'company-1');
      expect(repository.selectCalls, 1);
      expect(repository.clearCalls, 0);
    });

    test('returns load failure unchanged without selection', () async {
      const expected = FailureResult<List<CurrentCompanyContext>>(
        ServerFailure(code: FailureCodes.serverError),
      );
      final repository = _FakeCompanyContextRepository(loadResult: expected);

      final result = await LoadCurrentCompanyContextUseCase(repository)(
        const NoParams(),
      );

      expect(result.failureOrNull, same(expected.failureOrNull));
      expect(repository.selectCalls, 0);
      expect(repository.clearCalls, 0);
    });

    test('returns selection failure unchanged', () async {
      const context = _firstContext;
      const expected = FailureResult<CurrentCompanyContext>(
        ValidationFailure(code: CompanyFailureCodes.companyNotAvailable),
      );
      final repository = _FakeCompanyContextRepository(
        loadResult: const Success([context]),
        selectResult: expected,
      );

      final result = await LoadCurrentCompanyContextUseCase(repository)(
        const NoParams(),
      );

      expect(result.failureOrNull, same(expected.failureOrNull));
      expect(repository.selectCalls, 1);
    });
  });
}

const _firstContext = CurrentCompanyContext(
  company: Company(id: 'company-1', name: 'Company'),
  role: CompanyRole.owner,
);

const _secondContext = CurrentCompanyContext(
  company: Company(id: 'company-2', name: 'Company'),
  role: CompanyRole.owner,
);

final class _FakeCompanyContextRepository implements CompanyContextRepository {
  final Result<List<CurrentCompanyContext>> loadResult;
  final Result<CurrentCompanyContext> selectResult;

  int selectCalls = 0;
  int clearCalls = 0;
  String? selectedCompanyId;

  _FakeCompanyContextRepository({
    Result<List<CurrentCompanyContext>>? loadResult,
    Result<CurrentCompanyContext>? selectResult,
  }) : loadResult = loadResult ?? const Success([]),
       selectResult =
           selectResult ??
           const FailureResult<CurrentCompanyContext>(UnexpectedFailure());

  @override
  Future<Result<List<CurrentCompanyContext>>> loadUserCompanyContexts() async =>
      loadResult;

  @override
  Future<Result<CurrentCompanyContext>> selectCompany(String companyId) async {
    selectCalls += 1;
    selectedCompanyId = companyId;
    return selectResult;
  }

  @override
  Future<Result<void>> clearCurrentCompanyContext() async {
    clearCalls += 1;
    return const Success(null);
  }

  @override
  Future<Result<CurrentCompanyContext?>> getCurrentCompanyContext() async =>
      const Success(null);
}
