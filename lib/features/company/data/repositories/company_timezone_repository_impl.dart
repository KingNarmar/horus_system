import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthException, PostgrestException;

import '../../../../core/utils/result.dart';
import '../../domain/entities/company.dart';
import '../../domain/repositories/company_timezone_repository.dart';
import '../../domain/value_objects/company_timezone.dart';
import '../datasources/company_timezone_remote_data_source.dart';
import '../mappers/company_mapper.dart';
import 'company_timezone_repository_failure_mapper.dart';

final class CompanyTimezoneRepositoryImpl implements CompanyTimezoneRepository {
  final CompanyTimezoneRemoteDataSource _remoteDataSource;

  const CompanyTimezoneRepositoryImpl(this._remoteDataSource);

  static const _failureMapper = CompanyTimezoneRepositoryFailureMapper();

  @override
  Future<Result<List<CompanyTimezone>>> getTimezoneOptions() {
    return _guard(() async {
      final rawOptions = await _remoteDataSource.getTimezoneOptions();
      return rawOptions
          .map((rawOption) {
            final option = CompanyTimezone.tryParse(rawOption);
            if (option == null) {
              throw const FormatException('Invalid timezone option.');
            }
            return option;
          })
          .toList(growable: false);
    });
  }

  @override
  Future<Result<Company>> updateBusinessTimezone({
    required String companyId,
    required CompanyTimezone businessTimezone,
  }) {
    return _guard(
      () async => (await _remoteDataSource.updateBusinessTimezone(
        companyId: companyId,
        businessTimezone: businessTimezone.value,
      )).toEntity(),
    );
  }

  Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Success(await action());
    } on AuthException catch (error) {
      return FailureResult(_failureMapper.fromAuthException(error));
    } on PostgrestException catch (error) {
      return FailureResult(_failureMapper.fromPostgrest(error));
    } on FormatException catch (error) {
      return FailureResult(_failureMapper.fromFormatException(error));
    } catch (error) {
      return FailureResult(_failureMapper.fromUnexpected(error));
    }
  }
}
