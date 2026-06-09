import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../../../core/context/current_company_provider.dart';
import '../../../../core/errors/common_failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/company_user.dart';
import '../../domain/repositories/company_users_repository.dart';
import '../datasources/company_users_remote_data_source.dart';
import '../mappers/company_user_mapper.dart';

class CompanyUsersRepositoryImpl implements CompanyUsersRepository {
  final CompanyUsersRemoteDataSource _remoteDataSource;
  final CurrentCompanyProvider _currentCompanyProvider;

  const CompanyUsersRepositoryImpl({
    required CompanyUsersRemoteDataSource remoteDataSource,
    required CurrentCompanyProvider currentCompanyProvider,
  })  : _remoteDataSource = remoteDataSource,
        _currentCompanyProvider = currentCompanyProvider;

  @override
  Future<Result<List<CompanyUser>>> getCompanyUsers() async {
    try {
      final companyId = _currentCompanyProvider.requireCurrentCompanyId();
      final models = await _remoteDataSource.getCompanyUsers(
        companyId: companyId,
      );

      return Success(
        models.map((model) => model.toEntity()).toList(),
      );
    } on MissingCompanyContextException catch (error) {
      return FailureResult(PermissionFailure(message: error.message));
    } on PostgrestException catch (error) {
      return FailureResult(
        ServerFailure(message: error.message, code: error.code),
      );
    } catch (error) {
      return FailureResult(UnexpectedFailure(message: error.toString()));
    }
  }
}
