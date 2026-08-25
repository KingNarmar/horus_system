import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../../../core/utils/result.dart';
import '../../domain/entities/company_user.dart';
import '../../domain/repositories/company_users_repository.dart';
import '../datasources/company_users_remote_data_source.dart';
import '../mappers/company_user_mapper.dart';
import 'company_users_repository_failure_mapper.dart';

class CompanyUsersRepositoryImpl implements CompanyUsersRepository {
  final CompanyUsersRemoteDataSource _remoteDataSource;

  const CompanyUsersRepositoryImpl({
    required CompanyUsersRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  static const _failureMapper = CompanyUsersRepositoryFailureMapper();

  @override
  Future<Result<List<CompanyUser>>> getCompanyUsers({
    required String companyId,
  }) {
    return _guard(
      () async => (await _remoteDataSource.getCompanyUsers(
        companyId: companyId,
      )).map((model) => model.toEntity()).toList(),
    );
  }

  Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Success(await action());
    } on PostgrestException catch (error) {
      return FailureResult(_failureMapper.fromPostgrest(error));
    } catch (error) {
      return FailureResult(_failureMapper.fromUnexpected(error));
    }
  }
}
