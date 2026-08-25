import 'package:horus_system/core/context/current_company_provider.dart';
import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/features/company/data/datasources/company_context_remote_data_source.dart';
import 'package:horus_system/features/company/data/models/company_membership_model.dart';
import 'package:horus_system/features/company/data/models/company_model.dart';
import 'package:horus_system/features/company/data/repositories/company_context_repository_impl.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/failures/company_failure_codes.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:test/test.dart';

void main() {
  group('CompanyContextRepositoryImpl', () {
    test('loads and maps memberships preserving order and content', () async {
      final dataSource = _FakeCompanyContextRemoteDataSource(
        memberships: [
          _membership('company-2', 'Second Company', CompanyRole.admin),
          _membership('company-1', 'First Company', CompanyRole.owner),
        ],
      );
      final repository = _repository(dataSource: dataSource);

      final result = await repository.loadUserCompanyContexts();

      expect(result.failureOrNull, isNull);
      expect(result.dataOrNull?.map((item) => item.companyId).toList(), [
        'company-2',
        'company-1',
      ]);
      expect(result.dataOrNull?.map((item) => item.company.name).toList(), [
        'Second Company',
        'First Company',
      ]);
      expect(result.dataOrNull?.map((item) => item.role).toList(), [
        CompanyRole.admin,
        CompanyRole.owner,
      ]);
    });

    test('maps auth failures through sanitized boundary', () async {
      final repository = _repository(
        dataSource: _FakeCompanyContextRemoteDataSource(
          error: AuthException(
            'secret authentication detail',
            statusCode: '401',
          ),
        ),
      );

      final result = await repository.loadUserCompanyContexts();

      expect(result.failureOrNull, isA<AuthFailure>());
      expect(result.failureOrNull?.code, CompanyFailureCodes.authRequired);
      expect(result.failureOrNull?.message, isNull);
    });

    test('maps PostgREST failures through sanitized boundary', () async {
      final repository = _repository(
        dataSource: _FakeCompanyContextRemoteDataSource(
          error: const PostgrestException(
            message: 'secret backend message',
            code: 'XX999',
            details: 'private database details',
            hint: 'internal database hint',
          ),
        ),
      );

      final result = await repository.loadUserCompanyContexts();

      expect(result.failureOrNull, isA<ServerFailure>());
      expect(result.failureOrNull?.code, FailureCodes.serverError);
      expect(result.failureOrNull?.message, isNull);
    });

    test('maps unexpected datasource failures without internal text', () async {
      final repository = _repository(
        dataSource: _FakeCompanyContextRemoteDataSource(
          error: StateError('secret datasource detail'),
        ),
      );

      final result = await repository.loadUserCompanyContexts();

      expect(result.failureOrNull, isA<UnexpectedFailure>());
      expect(result.failureOrNull?.message, isNull);
    });

    test('keeps model mapping inside sanitized boundary', () async {
      final repository = _repository(
        dataSource: _FakeCompanyContextRemoteDataSource(
          memberships: [_ThrowingCompanyMembershipModel()],
        ),
      );

      final result = await repository.loadUserCompanyContexts();

      expect(result.failureOrNull, isA<UnexpectedFailure>());
      expect(result.failureOrNull?.message, isNull);
    });

    test('loads memberships before selecting when cache is empty', () async {
      final dataSource = _FakeCompanyContextRemoteDataSource(
        memberships: [_membership()],
      );
      final provider = _FakeCurrentCompanyProvider();
      final repository = _repository(
        dataSource: dataSource,
        provider: provider,
      );

      final result = await repository.selectCompany('company-1');

      expect(result.dataOrNull?.companyId, 'company-1');
      expect(dataSource.calls, 1);
      expect(provider.currentCompanyId, 'company-1');
    });

    test('selects from populated cache without reloading', () async {
      final dataSource = _FakeCompanyContextRemoteDataSource(
        memberships: [_membership()],
      );
      final repository = _repository(dataSource: dataSource);
      await repository.loadUserCompanyContexts();

      final result = await repository.selectCompany('company-1');

      expect(result.dataOrNull?.companyId, 'company-1');
      expect(dataSource.calls, 1);
    });

    test('does not normalize selection input in Data', () async {
      final dataSource = _FakeCompanyContextRemoteDataSource(
        memberships: [_membership()],
      );
      final provider = _FakeCurrentCompanyProvider(initialId: 'original');
      final repository = _repository(
        dataSource: dataSource,
        provider: provider,
      );
      await repository.loadUserCompanyContexts();

      final result = await repository.selectCompany(' company-1 ');

      expect(result.failureOrNull, isA<ValidationFailure>());
      expect(
        result.failureOrNull?.code,
        CompanyFailureCodes.companyNotAvailable,
      );
      expect(result.failureOrNull?.message, isNull);
      expect(provider.currentCompanyId, 'original');
    });

    test('sanitizes provider selection failures', () async {
      final provider = _FakeCurrentCompanyProvider(throwOnSet: true);
      final repository = _repository(
        dataSource: _FakeCompanyContextRemoteDataSource(
          memberships: [_membership()],
        ),
        provider: provider,
      );

      final result = await repository.selectCompany('company-1');

      expect(result.failureOrNull, isA<ValidationFailure>());
      expect(
        result.failureOrNull?.code,
        FailureCodes.validationCompanyContextRequired,
      );
      expect(result.failureOrNull?.message, isNull);
    });

    test('returns null without loading for null stored company id', () async {
      final dataSource = _FakeCompanyContextRemoteDataSource();
      final repository = _repository(dataSource: dataSource);

      final result = await repository.getCurrentCompanyContext();

      expect(result.failureOrNull, isNull);
      expect(result.dataOrNull, isNull);
      expect(dataSource.calls, 0);
    });

    test('returns null without loading for blank stored company id', () async {
      final dataSource = _FakeCompanyContextRemoteDataSource();
      final repository = _repository(
        dataSource: dataSource,
        provider: _FakeCurrentCompanyProvider(initialId: '   '),
      );

      final result = await repository.getCurrentCompanyContext();

      expect(result.failureOrNull, isNull);
      expect(result.dataOrNull, isNull);
      expect(dataSource.calls, 0);
    });

    test('lazily loads and returns matching current context', () async {
      final dataSource = _FakeCompanyContextRemoteDataSource(
        memberships: [_membership()],
      );
      final repository = _repository(
        dataSource: dataSource,
        provider: _FakeCurrentCompanyProvider(initialId: 'company-1'),
      );

      final result = await repository.getCurrentCompanyContext();

      expect(result.dataOrNull?.companyId, 'company-1');
      expect(dataSource.calls, 1);
    });

    test('clears stale stored company id', () async {
      final provider = _FakeCurrentCompanyProvider(initialId: 'company-stale');
      final repository = _repository(
        dataSource: _FakeCompanyContextRemoteDataSource(
          memberships: [_membership()],
        ),
        provider: provider,
      );

      final result = await repository.getCurrentCompanyContext();

      expect(result.failureOrNull, isNull);
      expect(result.dataOrNull, isNull);
      expect(provider.currentCompanyId, isNull);
      expect(provider.clearCalls, 1);
    });

    test('clear removes provider state and cached contexts', () async {
      final dataSource = _FakeCompanyContextRemoteDataSource(
        memberships: [_membership()],
      );
      final provider = _FakeCurrentCompanyProvider(initialId: 'company-1');
      final repository = _repository(
        dataSource: dataSource,
        provider: provider,
      );
      await repository.loadUserCompanyContexts();

      final clearResult = await repository.clearCurrentCompanyContext();
      final selectResult = await repository.selectCompany('company-1');

      expect(clearResult.failureOrNull, isNull);
      expect(selectResult.dataOrNull?.companyId, 'company-1');
      expect(provider.clearCalls, 1);
      expect(dataSource.calls, 2);
    });

    test('sanitizes unexpected current-context provider failures', () async {
      final repository = _repository(
        dataSource: _FakeCompanyContextRemoteDataSource(),
        provider: _FakeCurrentCompanyProvider(throwOnGet: true),
      );

      final result = await repository.getCurrentCompanyContext();

      expect(result.failureOrNull, isA<UnexpectedFailure>());
      expect(result.failureOrNull?.message, isNull);
    });

    test('sanitizes unexpected clear failures', () async {
      final repository = _repository(
        dataSource: _FakeCompanyContextRemoteDataSource(),
        provider: _FakeCurrentCompanyProvider(throwOnClear: true),
      );

      final result = await repository.clearCurrentCompanyContext();

      expect(result.failureOrNull, isA<UnexpectedFailure>());
      expect(result.failureOrNull?.message, isNull);
    });
  });
}

CompanyContextRepositoryImpl _repository({
  required CompanyContextRemoteDataSource dataSource,
  CurrentCompanyProvider? provider,
}) {
  return CompanyContextRepositoryImpl(
    remoteDataSource: dataSource,
    currentCompanyProvider: provider ?? _FakeCurrentCompanyProvider(),
  );
}

CompanyMembershipModel _membership([
  String companyId = 'company-1',
  String companyName = 'Company',
  CompanyRole role = CompanyRole.owner,
]) {
  return CompanyMembershipModel(
    company: CompanyModel(id: companyId, name: companyName),
    role: role,
    isActive: true,
  );
}

final class _FakeCompanyContextRemoteDataSource
    implements CompanyContextRemoteDataSource {
  final List<CompanyMembershipModel> memberships;
  final Object? error;
  int calls = 0;

  _FakeCompanyContextRemoteDataSource({
    this.memberships = const [],
    this.error,
  });

  @override
  Future<List<CompanyMembershipModel>> loadUserCompanyMemberships() async {
    calls += 1;
    final failure = error;
    if (failure != null) throw failure;
    return memberships;
  }
}

final class _FakeCurrentCompanyProvider implements CurrentCompanyProvider {
  String? _companyId;
  final bool throwOnGet;
  final bool throwOnSet;
  final bool throwOnClear;
  int clearCalls = 0;

  _FakeCurrentCompanyProvider({
    String? initialId,
    this.throwOnGet = false,
    this.throwOnSet = false,
    this.throwOnClear = false,
  }) : _companyId = initialId;

  @override
  String? get currentCompanyId {
    if (throwOnGet) throw StateError('secret provider getter detail');
    return _companyId;
  }

  @override
  String requireCurrentCompanyId() {
    final companyId = currentCompanyId;
    if (companyId == null || companyId.trim().isEmpty) {
      throw const MissingCompanyContextException();
    }
    return companyId;
  }

  @override
  void setCurrentCompanyId(String companyId) {
    if (throwOnSet) {
      throw const MissingCompanyContextException(
        message: 'secret provider setter detail',
      );
    }
    _companyId = companyId;
  }

  @override
  void clear() {
    if (throwOnClear) throw StateError('secret provider clear detail');
    clearCalls += 1;
    _companyId = null;
  }
}

final class _ThrowingCompanyMembershipModel extends CompanyMembershipModel {
  _ThrowingCompanyMembershipModel()
    : super(
        company: const CompanyModel(id: 'company-1', name: 'Company'),
        role: CompanyRole.owner,
        isActive: true,
      );

  @override
  CompanyModel get company => throw StateError('secret mapping detail');
}
