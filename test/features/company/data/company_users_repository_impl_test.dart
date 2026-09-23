import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/company/data/datasources/company_users_remote_data_source.dart';
import 'package:horus_system/features/company/data/models/company_user_model.dart';
import 'package:horus_system/features/company/data/repositories/company_users_repository_impl.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:test/test.dart';

void main() {
  test('preserves inactive member identity through repository mapping', () async {
    final repository = CompanyUsersRepositoryImpl(
      remoteDataSource: _FakeCompanyUsersRemoteDataSource([
        const CompanyUserModel(
          id: 'membership-1',
          companyId: 'company-1',
          userId: 'user-1',
          role: CompanyRole.driver,
          isActive: false,
          displayName: 'H.O.R.U.S Driver Test',
        ),
      ]),
    );

    final result = await repository.getCompanyUsers(companyId: 'company-1');

    expect(result, isA<Success>());
    final users = result.dataOrNull!;
    expect(users, hasLength(1));
    expect(users.single.isActive, isFalse);
    expect(users.single.displayName, 'H.O.R.U.S Driver Test');
  });
}

final class _FakeCompanyUsersRemoteDataSource
    implements CompanyUsersRemoteDataSource {
  final List<CompanyUserModel> users;

  const _FakeCompanyUsersRemoteDataSource(this.users);

  @override
  Future<List<CompanyUserModel>> getCompanyUsers({
    required String companyId,
  }) async {
    return users;
  }
}
