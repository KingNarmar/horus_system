import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthException, PostgrestException;

import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure_codes.dart';
import '../../../../core/utils/result.dart';
import '../../../company/domain/failures/company_failure_codes.dart';
import '../../domain/entities/dashboard_source.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../datasources/dashboard_remote_data_source.dart';
import '../mappers/dashboard_failure_mapper.dart';
import '../mappers/dashboard_source_mapper.dart';

final class DashboardRepositoryImpl implements DashboardRepository {
  final DashboardRemoteDataSource _remoteDataSource;

  const DashboardRepositoryImpl(this._remoteDataSource);

  @override
  Future<Result<DashboardSource>> getDashboardSource({
    required String companyId,
  }) async {
    try {
      final model = await _remoteDataSource.getDashboardSource(
        companyId: companyId,
      );
      return Success(model.toEntity());
    } on AuthException {
      return const FailureResult(
        AuthFailure(code: CompanyFailureCodes.authRequired),
      );
    } on PostgrestException catch (error) {
      return FailureResult(DashboardFailureMapper.fromPostgrest(error));
    } on FormatException {
      return const FailureResult(ServerFailure(code: FailureCodes.serverError));
    } catch (_) {
      return const FailureResult(UnexpectedFailure());
    }
  }
}
