import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/entities/company_user.dart';
import 'package:horus_system/features/company/domain/entities/current_company_context.dart';
import 'package:horus_system/features/company/domain/repositories/company_users_repository.dart';
import 'package:horus_system/features/company/domain/usecases/get_company_users_usecase.dart';
import 'package:test/test.dart';

void main() {
  group('GetCompanyUsersUseCase', () {
    test('rejects unauthorized roles without calling repository', () async {
      final repository = _FakeCompanyUsersRepository();
      final result = await GetCompanyUsersUseCase(repository)(
        GetCompanyUsersParams(
          currentCompanyContext: _context(role: CompanyRole.viewer),
        ),
      );

      expect(result.failureOrNull, isA<PermissionFailure>());
      expect(
        result.failureOrNull?.code,
        FailureCodes.permissionCompanyUsersView,
      );
      expect(result.failureOrNull?.message, isNull);
      expect(repository.calls, 0);
    });

    test('checks permission before company id validation', () async {
      final repository = _FakeCompanyUsersRepository();
      final result = await GetCompanyUsersUseCase(repository)(
        GetCompanyUsersParams(
          currentCompanyContext: _context(
            companyId: '   ',
            role: CompanyRole.viewer,
          ),
        ),
      );

      expect(result.failureOrNull, isA<PermissionFailure>());
      expect(
        result.failureOrNull?.code,
        FailureCodes.permissionCompanyUsersView,
      );
      expect(repository.calls, 0);
    });

    test('rejects empty normalized company id without repository call', () async {
      final repository = _FakeCompanyUsersRepository();
      final result = await GetCompanyUsersUseCase(repository)(
        GetCompanyUsersParams(
          currentCompanyContext: _context(companyId: '   '),
        ),
      );

      expect(result.failureOrNull, isA<ValidationFailure>());
      expect(
        result.failureOrNull?.code,
        FailureCodes.validationCompanyIdRequired,
      );
      expect(result.failureOrNull?.message, isNull);
      expect(repository.calls, 0);
    });

    test('normalizes company id before repository call', () async {
      final repository = _FakeCompanyUsersRepository();
      final result = await GetCompanyUsersUseCase(repository)(
        GetCompanyUsersParams(
          currentCompanyContext: _context(companyId: ' company-1 '),
        ),
      );

      expect(result.isSuccess, isTrue);
      expect(repository.calls, 1);
      expect(repository.companyId, 'company-1');
    });

    test('returns repository result unchanged', () async {
      final expected = FailureResult<List<CompanyUser>>(
        const ServerFailure(code: FailureCodes.serverError),
      );
      final repository = _FakeCompanyUsersRepository(result: expected);

      final result = await GetCompanyUsersUseCase(repository)(
        GetCompanyUsersParams(currentCompanyContext: _context()),
      );

      expect(result, same(expected));
      expect(repository.calls, 1);
    });
  });
}

CurrentCompanyContext _context({
  String companyId = 'company-1',
  CompanyRole role = CompanyRole.owner,
}) {
  return CurrentCompanyContext(
    company: Company(id: companyId, name: 'Horus Transport'),
    role: role,
  );
}

final class _FakeCompanyUsersRepository implements CompanyUsersRepository {
  final Result<List<CompanyUser>> result;

  int calls = 0;
  String? companyId;

  _FakeCompanyUsersRepository({Result<List<CompanyUser>>? result})
    : result = result ?? const Success<List<CompanyUser>>(<CompanyUser>[]);

  @override
  Future<Result<List<CompanyUser>>> getCompanyUsers({
    required String companyId,
  }) async {
    calls += 1;
    this.companyId = companyId;
    return result;
  }
}
