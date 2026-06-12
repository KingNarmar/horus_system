import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../../../core/errors/common_failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/company_user.dart';
import '../../domain/repositories/company_users_repository.dart';
import '../datasources/company_users_remote_data_source.dart';
import '../mappers/company_user_mapper.dart';

class CompanyUsersRepositoryImpl implements CompanyUsersRepository {
  final CompanyUsersRemoteDataSource _remoteDataSource;

  const CompanyUsersRepositoryImpl({
    required CompanyUsersRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  @override
  Future<Result<List<CompanyUser>>> getCompanyUsers({
    required String companyId,
  }) async {
    try {
      final normalizedCompanyId = companyId.trim();

      if (normalizedCompanyId.isEmpty) {
        return const FailureResult(
          ValidationFailure(code: FailureCodes.validationCompanyIdRequired, message: 'Company id is required.'),
        );
      }

      final models = await _remoteDataSource.getCompanyUsers(
        companyId: normalizedCompanyId,
      );

      return Success(models.map((model) => model.toEntity()).toList());
    } on PostgrestException catch (error) {
      return FailureResult(
        ServerFailure(code: error.code ?? FailureCodes.serverError, message: error.message),
      );
    } catch (error) {
      return FailureResult(UnexpectedFailure(message: error.toString()));
    }
  }
}
