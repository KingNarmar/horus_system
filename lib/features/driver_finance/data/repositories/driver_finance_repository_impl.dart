import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../../../core/utils/result.dart';
import '../../../audit/domain/usecases/create_audit_log_usecase.dart';
import '../../domain/entities/driver_finance_trip_option.dart';
import '../../domain/entities/driver_financial_movement.dart';
import '../../domain/entities/driver_financial_movement_write_data.dart';
import '../../domain/repositories/driver_finance_repository.dart';
import '../datasources/driver_finance_remote_data_source.dart';
import '../mappers/driver_finance_trip_option_mapper.dart';
import '../mappers/driver_financial_movement_mapper.dart';
import 'driver_finance_repository_audit_writer.dart';
import 'driver_finance_repository_failure_mapper.dart';

class DriverFinanceRepositoryImpl implements DriverFinanceRepository {
  final DriverFinanceRemoteDataSource remoteDataSource;
  final CreateAuditLogUseCase createAuditLogUseCase;
  final DriverFinanceRepositoryFailureMapper _failureMapper;

  const DriverFinanceRepositoryImpl({
    required this.remoteDataSource,
    required this.createAuditLogUseCase,
  }) : _failureMapper = const DriverFinanceRepositoryFailureMapper();

  DriverFinanceRepositoryAuditWriter get _auditWriter {
    return DriverFinanceRepositoryAuditWriter(createAuditLogUseCase);
  }

  @override
  Future<Result<List<DriverFinancialMovement>>> getDriverMovements({
    required String companyId,
    required String driverId,
  }) {
    return _guard(() async {
      final models = await remoteDataSource.getDriverMovements(
        companyId: companyId,
        driverId: driverId,
      );
      return Success(models.map((model) => model.toEntity()).toList());
    });
  }

  @override
  Future<Result<List<DriverFinanceTripOption>>> getDriverTripOptions({
    required String companyId,
    required String driverId,
  }) {
    return _guard(() async {
      final models = await remoteDataSource.getDriverTripOptions(
        companyId: companyId,
        driverId: driverId,
      );
      return Success(models.map((model) => model.toEntity()).toList());
    });
  }

  @override
  Future<Result<DriverFinancialMovement>> addDriverMovement({
    required DriverFinancialMovementWriteData data,
    required String actorRole,
  }) {
    return _guard(() async {
      final model = await remoteDataSource.addDriverMovement(data: data);
      final auditFailure = await _auditWriter.writeAdded(
        movement: model,
        actorRole: actorRole,
      );

      if (auditFailure != null) {
        return FailureResult<DriverFinancialMovement>(auditFailure);
      }
      return Success(model.toEntity());
    });
  }

  Future<Result<T>> _guard<T>(Future<Result<T>> Function() action) async {
    try {
      return await action();
    } on PostgrestException catch (error) {
      return FailureResult(_failureMapper.fromMovementPostgrest(error));
    } catch (error) {
      return FailureResult(_failureMapper.fromUnexpected(error));
    }
  }
}
