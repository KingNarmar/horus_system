import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../../../core/utils/result.dart';
import '../../domain/entities/driver_balance.dart';
import '../../domain/repositories/driver_balance_repository.dart';
import '../datasources/canonical_driver_balance_remote_data_source.dart';
import '../mappers/driver_balance_mapper.dart';
import 'driver_finance_repository_failure_mapper.dart';

class DriverBalanceRepositoryImpl implements DriverBalanceRepository {
  final CanonicalDriverBalanceRemoteDataSource remoteDataSource;
  final DriverFinanceRepositoryFailureMapper _failureMapper;

  const DriverBalanceRepositoryImpl({required this.remoteDataSource})
    : _failureMapper = const DriverFinanceRepositoryFailureMapper();

  @override
  Future<Result<DriverBalance>> getCanonicalDriverBalance({
    required String companyId,
    required String driverId,
    required DateTime beforeExclusive,
    DateTime? checkpointBeforeExclusive,
  }) async {
    try {
      final model = await remoteDataSource.getCanonicalDriverBalance(
        companyId: companyId,
        driverId: driverId,
        beforeExclusive: beforeExclusive,
        checkpointBeforeExclusive: checkpointBeforeExclusive,
      );
      return Success(model.toEntity());
    } on PostgrestException catch (error) {
      return FailureResult(_failureMapper.fromBalancePostgrest(error));
    } catch (error) {
      return FailureResult(_failureMapper.fromUnexpected(error));
    }
  }
}
