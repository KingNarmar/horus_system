import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/features/company/data/datasources/company_users_remote_data_source.dart';
import 'package:horus_system/features/company/data/models/company_user_model.dart';
import 'package:horus_system/features/company/data/repositories/company_users_repository_impl.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:test/test.dart';

void main() {
  group('CompanyUsersRepositoryImpl', () {
    test('forwards company id exactly without Data normalization', () async {
      final dataSource = _FakeCompanyUsersRemoteDataSource();
      final repository = CompanyUsersRepositoryImpl(
        remoteDataSource: dataSource,
      );

      final result = await repository.getCompanyUsers(companyId: ' company-1 ');

      expect(result.failureOrNull, isNull);
      expect(dataSource.calls, 1);
      expect(dataSource.companyId, ' company-1 ');
    });

    test('maps models preserving list order and content', () async {
      final dataSource = _FakeCompanyUsersRemoteDataSource(
        models: const [
          CompanyUserModel(
            id: 'company-user-2',
            companyId: 'company-1',
            userId: 'user-2',
            displayName: 'Second User',
            phone: '+971500000002',
            role: CompanyRole.admin,
            isActive: true,
          ),
          CompanyUserModel(
            id: 'company-user-1',
            companyId: 'company-1',
            userId: 'user-1',
            displayName: 'First User',
            phone: '+971500000001',
            role: CompanyRole.owner,
            isActive: false,
          ),
        ],
      );
      final repository = CompanyUsersRepositoryImpl(
        remoteDataSource: dataSource,
      );

      final result = await repository.getCompanyUsers(companyId: 'company-1');

      expect(result.failureOrNull, isNull);
      expect(result.dataOrNull?.map((user) => user.id).toList(), [
        'company-user-2',
        'company-user-1',
      ]);
      expect(result.dataOrNull?.map((user) => user.userId).toList(), [
        'user-2',
        'user-1',
      ]);
      expect(result.dataOrNull?.map((user) => user.displayName).toList(), [
        'Second User',
        'First User',
      ]);
      expect(result.dataOrNull?.map((user) => user.phone).toList(), [
        '+971500000002',
        '+971500000001',
      ]);
      expect(result.dataOrNull?.map((user) => user.role).toList(), [
        CompanyRole.admin,
        CompanyRole.owner,
      ]);
      expect(result.dataOrNull?.map((user) => user.isActive).toList(), [
        true,
        false,
      ]);
    });

    test('preserves nullable optional profile fields', () async {
      final repository = CompanyUsersRepositoryImpl(
        remoteDataSource: _FakeCompanyUsersRemoteDataSource(
          models: const [
            CompanyUserModel(
              id: 'company-user-1',
              companyId: 'company-1',
              userId: 'user-1',
              role: CompanyRole.admin,
              isActive: true,
            ),
          ],
        ),
      );

      final result = await repository.getCompanyUsers(companyId: 'company-1');

      expect(result.failureOrNull, isNull);
      expect(result.dataOrNull?.single.displayName, isNull);
      expect(result.dataOrNull?.single.phone, isNull);
    });

    test(
      'maps datasource PostgREST failures through sanitized boundary',
      () async {
        final repository = CompanyUsersRepositoryImpl(
          remoteDataSource: _FakeCompanyUsersRemoteDataSource(
            error: const PostgrestException(
              message: 'secret backend message',
              code: 'XX999',
              details: 'private database details',
              hint: 'internal database hint',
            ),
          ),
        );

        final result = await repository.getCompanyUsers(companyId: 'company-1');

        expect(result.failureOrNull, isA<ServerFailure>());
        expect(result.failureOrNull?.code, FailureCodes.serverError);
        expect(result.failureOrNull?.message, isNull);
      },
    );

    test('maps unexpected datasource failure without internal text', () async {
      final repository = CompanyUsersRepositoryImpl(
        remoteDataSource: _FakeCompanyUsersRemoteDataSource(
          error: StateError('secret datasource implementation detail'),
        ),
      );

      final result = await repository.getCompanyUsers(companyId: 'company-1');

      expect(result.failureOrNull, isA<UnexpectedFailure>());
      expect(result.failureOrNull?.message, isNull);
    });

    test('keeps model mapping inside sanitized guard boundary', () async {
      final repository = CompanyUsersRepositoryImpl(
        remoteDataSource: _FakeCompanyUsersRemoteDataSource(
          models: [_ThrowingCompanyUserModel()],
        ),
      );

      final result = await repository.getCompanyUsers(companyId: 'company-1');

      expect(result.failureOrNull, isA<UnexpectedFailure>());
      expect(result.failureOrNull?.message, isNull);
    });
  });
}

final class _FakeCompanyUsersRemoteDataSource
    implements CompanyUsersRemoteDataSource {
  final List<CompanyUserModel> models;
  final Object? error;

  int calls = 0;
  String? companyId;

  _FakeCompanyUsersRemoteDataSource({this.models = const [], this.error});

  @override
  Future<List<CompanyUserModel>> getCompanyUsers({
    required String companyId,
  }) async {
    calls += 1;
    this.companyId = companyId;

    final failure = error;
    if (failure != null) throw failure;
    return models;
  }
}

final class _ThrowingCompanyUserModel extends CompanyUserModel {
  _ThrowingCompanyUserModel()
    : super(
        id: 'company-user-1',
        companyId: 'company-1',
        userId: 'user-1',
        role: CompanyRole.owner,
        isActive: true,
      );

  @override
  String get id => throw StateError('secret model mapping detail');
}
