import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthException, PostgrestException;

import '../../../../core/utils/result.dart';
import '../../domain/entities/company.dart';
import '../../domain/repositories/company_repository.dart';
import '../../domain/value_objects/company_timezone.dart';
import '../datasources/company_remote_data_source.dart';
import '../mappers/company_mapper.dart';
import 'company_repository_failure_mapper.dart';

class CompanyRepositoryImpl implements CompanyRepository {
  final CompanyRemoteDataSource _remoteDataSource;

  const CompanyRepositoryImpl(this._remoteDataSource);

  static const _failureMapper = CompanyRepositoryFailureMapper();

  @override
  Future<Result<Company>> createCompany({
    required String name,
    required CompanyTimezone businessTimezone,
    String? businessType,
    String? phone,
    String? email,
    String? country,
    String? city,
  }) {
    return _guard(
      () async => (await _remoteDataSource.createCompany(
        name: name,
        businessTimezone: businessTimezone.value,
        businessType: businessType,
        phone: phone,
        email: email,
        country: country,
        city: city,
      )).toEntity(),
    );
  }

  @override
  Future<Result<List<Company>>> getMyCompanies() {
    return _guard(
      () async => (await _remoteDataSource.getMyCompanies())
          .map((company) => company.toEntity())
          .toList(),
    );
  }

  Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Success(await action());
    } on AuthException catch (error) {
      return FailureResult(_failureMapper.fromAuthException(error));
    } on PostgrestException catch (error) {
      return FailureResult(_failureMapper.fromPostgrest(error));
    } catch (error) {
      return FailureResult(_failureMapper.fromUnexpected(error));
    }
  }
}
