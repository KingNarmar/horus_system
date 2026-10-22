import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../../../core/domain/value_objects/business_date.dart';
import '../../../../core/domain/value_objects/currency_code.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/driver_balance_activity.dart';
import '../../domain/repositories/driver_balance_activity_repository.dart';
import '../datasources/canonical_driver_balance_remote_data_source.dart';
import 'driver_finance_repository_failure_mapper.dart';

final class DriverBalanceActivityRepositoryImpl
    implements DriverBalanceActivityRepository {
  final DriverBalanceActivityRemoteDataSource remoteDataSource;
  final DriverFinanceRepositoryFailureMapper _failureMapper;

  const DriverBalanceActivityRepositoryImpl({
    required this.remoteDataSource,
    DriverFinanceRepositoryFailureMapper failureMapper =
        const DriverFinanceRepositoryFailureMapper(),
  }) : _failureMapper = failureMapper;

  @override
  Future<Result<DriverBalanceActivity>> getDriverBalanceActivity({
    required String companyId,
    required String driverId,
    required CurrencyCode currency,
    required int currencyFractionDigits,
    required BusinessDate beforeExclusive,
    BusinessDate? checkpointBeforeExclusive,
  }) async {
    try {
      final activity = await remoteDataSource.getDriverBalanceActivity(
        companyId: companyId,
        driverId: driverId,
        currencyCode: currency.value,
        currencyFractionDigits: currencyFractionDigits,
        beforeExclusive: beforeExclusive,
        checkpointBeforeExclusive: checkpointBeforeExclusive,
      );
      return Success(activity);
    } on PostgrestException catch (error) {
      return FailureResult(_failureMapper.fromBalancePostgrest(error));
    } catch (error) {
      return FailureResult(_failureMapper.fromUnexpected(error));
    }
  }
}
