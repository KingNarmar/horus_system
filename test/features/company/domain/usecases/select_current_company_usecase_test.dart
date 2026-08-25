import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/company/domain/entities/current_company_context.dart';
import 'package:horus_system/features/company/domain/repositories/company_context_repository.dart';
import 'package:horus_system/features/company/domain/usecases/select_current_company_usecase.dart';
import 'package:test/test.dart';

void main() {
  group('SelectCurrentCompanyUseCase', () {
    test('rejects empty normalized id without repository call', () async {
      final repository = _FakeCompanyContextRepository();

      final result = await SelectCurrentCompanyUseCase(repository)(
        const SelectCurrentCompanyParams(companyId: '   '),
      );

      expect(result.failureOrNull, isA<ValidationFailure>());
      expect(
        result.failureOrNull?.code,
        FailureCodes.validationCompanyContextRequired,
      );
      expect(result.failureOrNull?.message, isNull);
      expect(repository.selectCalls, 0);
    });

    test('normalizes company id before repository call', () async {
      final repository = _FakeCompanyContextRepository();

      await SelectCurrentCompanyUseCase(repository)(
        const SelectCurrentCompanyParams(companyId: ' company-1 '),
      );

      expect(repository.selectCalls, 1);
      expect(repository.selectedCompanyId, 'company-1');
    });

    test('returns repository result unchanged', () async {
      const expected = FailureResult<CurrentCompanyContext>(
        ServerFailure(code: FailureCodes.serverError),
      );
      final repository = _FakeCompanyContextRepository(selectResult: expected);

      final result = await SelectCurrentCompanyUseCase(repository)(
        const SelectCurrentCompanyParams(companyId: 'company-1'),
      );

      expect(result, same(expected));
    });
  });
}

final class _FakeCompanyContextRepository implements CompanyContextRepository {
  final Result<CurrentCompanyContext> selectResult;

  int selectCalls = 0;
  String? selectedCompanyId;

  _FakeCompanyContextRepository({Result<CurrentCompanyContext>? selectResult})
    : selectResult =
          selectResult ??
          const FailureResult<CurrentCompanyContext>(UnexpectedFailure());

  @override
  Future<Result<CurrentCompanyContext>> selectCompany(String companyId) async {
    selectCalls += 1;
    selectedCompanyId = companyId;
    return selectResult;
  }

  @override
  Future<Result<List<CurrentCompanyContext>>> loadUserCompanyContexts() async =>
      const Success([]);

  @override
  Future<Result<CurrentCompanyContext?>> getCurrentCompanyContext() async =>
      const Success(null);

  @override
  Future<Result<void>> clearCurrentCompanyContext() async =>
      const Success(null);
}
