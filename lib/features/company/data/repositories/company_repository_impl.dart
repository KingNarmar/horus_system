import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthException, PostgrestException;

import '../../../../core/errors/common_failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/company.dart';
import '../../domain/repositories/company_repository.dart';
import '../datasources/company_remote_data_source.dart';
import '../mappers/company_mapper.dart';

class CompanyRepositoryImpl implements CompanyRepository {
  final CompanyRemoteDataSource _remoteDataSource;

  const CompanyRepositoryImpl(this._remoteDataSource);

  @override
  Future<Result<Company>> createCompany({
    required String name,
    String? businessType,
    String? phone,
    String? email,
    String? country,
    String? city,
  }) async {
    try {
      final companyModel = await _remoteDataSource.createCompany(
        name: name,
        businessType: businessType,
        phone: phone,
        email: email,
        country: country,
        city: city,
      );

      return Success(companyModel.toEntity());
    } on AuthException catch (error) {
      return FailureResult(
        AuthFailure(
          code: error.statusCode ?? 'auth_error',
          message: error.message,
        ),
      );
    } on PostgrestException catch (error) {
      return FailureResult(
        ServerFailure(
          code: error.code ?? FailureCodes.serverError,
          message: error.message,
        ),
      );
    } catch (error) {
      return FailureResult(UnexpectedFailure(message: error.toString()));
    }
  }

  @override
  Future<Result<List<Company>>> getMyCompanies() async {
    try {
      final companyModels = await _remoteDataSource.getMyCompanies();
      return Success(
        companyModels.map((company) => company.toEntity()).toList(),
      );
    } on AuthException catch (error) {
      return FailureResult(
        AuthFailure(
          code: error.statusCode ?? 'auth_error',
          message: error.message,
        ),
      );
    } on PostgrestException catch (error) {
      return FailureResult(
        ServerFailure(
          code: error.code ?? FailureCodes.serverError,
          message: error.message,
        ),
      );
    } catch (error) {
      return FailureResult(UnexpectedFailure(message: error.toString()));
    }
  }
}
