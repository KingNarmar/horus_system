import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/errors/failure_codes.dart';
import '../../../../core/utils/result.dart';
import '../../../audit/domain/entities/audit_action.dart';
import '../../../audit/domain/entities/audit_entity_type.dart';
import '../../../audit/domain/entities/audit_log_write_data.dart';
import '../../../audit/domain/entities/audit_module.dart';
import '../../../audit/domain/usecases/create_audit_log_usecase.dart';
import '../../domain/entities/driver_finance_trip_option.dart';
import '../../domain/entities/driver_financial_movement.dart';
import '../../domain/entities/driver_financial_movement_type.dart';
import '../../domain/entities/driver_financial_movement_write_data.dart';
import '../../domain/repositories/driver_finance_repository.dart';
import '../datasources/driver_finance_remote_data_source.dart';
import '../mappers/driver_finance_trip_option_mapper.dart';
import '../mappers/driver_financial_movement_mapper.dart';
import '../models/driver_financial_movement_model.dart';

const _driverFinancialMovementEntityKey = 'driver_financial_movement';
const _driverFinanceMovementAddedEvent = 'driver_finance_movement_added';

class DriverFinanceRepositoryImpl implements DriverFinanceRepository {
  final DriverFinanceRemoteDataSource remoteDataSource;
  final CreateAuditLogUseCase createAuditLogUseCase;

  const DriverFinanceRepositoryImpl({
    required this.remoteDataSource,
    required this.createAuditLogUseCase,
  });

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
      final auditFailure = await _writeAudit(
        companyId: model.companyId,
        driverId: model.driverId,
        actorRole: actorRole,
        movement: model,
      );

      if (auditFailure != null) {
        return FailureResult<DriverFinancialMovement>(auditFailure);
      }
      return Success(model.toEntity());
    });
  }

  Future<Failure?> _writeAudit({
    required String companyId,
    required String driverId,
    required String actorRole,
    required DriverFinancialMovementModel movement,
  }) async {
    final result = await createAuditLogUseCase(
      CreateAuditLogParams(
        data: AuditLogWriteData(
          companyId: companyId,
          actorRole: actorRole,
          module: AuditModule.drivers,
          entityType: AuditEntityType.driver,
          entityId: driverId,
          entityDisplayName: _driverFinancialMovementEntityKey,
          action: AuditAction.created,
          description: _driverFinanceMovementAddedEvent,
          newValues: movement.toAuditValues(),
          metadata: {
            'audit_event': _driverFinanceMovementAddedEvent,
            'movement_id': movement.id,
            'movement_type': movement.type.value,
            'amount': movement.amount,
            'trip_id': movement.tripId,
          },
        ),
      ),
    );

    return result.failureOrNull;
  }

  Future<Result<T>> _guard<T>(Future<Result<T>> Function() action) async {
    try {
      return await action();
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
