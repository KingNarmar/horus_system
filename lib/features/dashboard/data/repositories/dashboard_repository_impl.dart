import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthException, PostgrestException;

import '../../../../core/utils/result.dart';
import '../../domain/entities/dashboard_source.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../datasources/dashboard_remote_data_source.dart';
import '../mappers/dashboard_source_mapper.dart';
import 'dashboard_repository_failure_mapper.dart';

final class DashboardRepositoryImpl implements DashboardRepository {
  final DashboardRemoteDataSource _remoteDataSource;

  const DashboardRepositoryImpl(this._remoteDataSource);

  static const _failureMapper = DashboardRepositoryFailureMapper();

  @override
  Future<Result<DashboardSource>> getDashboardSource({
    required String companyId,
  }) {
    return _guard(
      () async => (await _remoteDataSource.getDashboardSource(
        companyId: companyId,
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
