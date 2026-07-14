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
import '../../domain/entities/driver_settlement.dart';
import '../../domain/entities/driver_settlement_driver_option.dart';
import '../../domain/entities/driver_settlement_period.dart';
import '../../domain/entities/driver_settlement_source_snapshot.dart';
import '../../domain/entities/driver_settlement_write_data.dart';
import '../../domain/repositories/driver_settlements_repository.dart';
import '../constants/driver_settlements_db_fields.dart';
import '../datasources/driver_settlements_remote_data_source.dart';
import '../mappers/driver_settlement_driver_option_mapper.dart';
import '../mappers/driver_settlement_mapper.dart';
import '../models/driver_settlement_model.dart';

class DriverSettlementsRepositoryImpl implements DriverSettlementsRepository {
  final DriverSettlementsRemoteDataSource remoteDataSource;
  final CreateAuditLogUseCase createAuditLogUseCase;

  const DriverSettlementsRepositoryImpl({
    required this.remoteDataSource,
    required this.createAuditLogUseCase,
  });

  @override
  Future<Result<List<DriverSettlement>>> getDriverSettlements({
    required String companyId,
    String? driverId,
    bool includeVoided = false,
  }) {
    return _guard(() async {
      final models = await remoteDataSource.getDriverSettlements(
        companyId: companyId,
        driverId: driverId,
        includeVoided: includeVoided,
      );
      return Success(models.map((model) => model.toEntity()).toList());
    });
  }

  @override
  Future<Result<List<DriverSettlementDriverOption>>> getDriverOptions({
    required String companyId,
  }) {
    return _guard(() async {
      final models = await remoteDataSource.getDriverOptions(
        companyId: companyId,
      );
      return Success(models.map((model) => model.toEntity()).toList());
    });
  }

  @override
  Future<Result<DriverSettlementDriverOption?>> getDriverOptionById({
    required String companyId,
    required String driverId,
  }) {
    return _guard(() async {
      final model = await remoteDataSource.getDriverOptionById(
        companyId: companyId,
        driverId: driverId,
      );
      return Success(model?.toEntity());
    });
  }

  @override
  Future<Result<DriverSettlement>> getDriverSettlementById({
    required String companyId,
    required String settlementId,
  }) {
    return _guard(() async {
      final model = await remoteDataSource.getDriverSettlementById(
        companyId: companyId,
        settlementId: settlementId,
      );
      return Success(model.toEntity());
    });
  }

  @override
  Future<Result<DriverSettlementSourceSnapshot>> getSettlementSourceSnapshot({
    required String companyId,
    required String driverId,
    required DriverSettlementPeriod period,
  }) {
    return _guard(() async {
      final snapshot = await remoteDataSource.getSettlementSourceSnapshot(
        companyId: companyId,
        driverId: driverId,
        period: period,
      );
      return Success(snapshot);
    });
  }

  @override
  Future<Result<DriverSettlement>> createDraft({
    required DriverSettlementDraftWriteData data,
    required String actorRole,
  }) {
    return _guard(() async {
      final model = await remoteDataSource.createDraft(data: data);
      return _withAudit(
        model: model,
        actorRole: actorRole,
        action: AuditAction.created,
        event: DriverSettlementAuditKeys.created,
      );
    });
  }

  @override
  Future<Result<DriverSettlement>> finalizeSettlement({
    required DriverSettlementFinalizeData data,
    required String actorRole,
  }) {
    return _guard(() async {
      final oldModel = await remoteDataSource.getDriverSettlementById(
        companyId: data.companyId,
        settlementId: data.settlementId,
      );
      final model = await remoteDataSource.finalizeSettlement(data: data);
      return _withAudit(
        model: model,
        actorRole: actorRole,
        action: AuditAction.statusChanged,
        event: DriverSettlementAuditKeys.finalized,
        oldValues: oldModel.toAuditValues(),
      );
    });
  }

  @override
  Future<Result<DriverSettlement>> voidSettlement({
    required DriverSettlementVoidData data,
    required String actorRole,
  }) {
    return _guard(() async {
      final oldModel = await remoteDataSource.getDriverSettlementById(
        companyId: data.companyId,
        settlementId: data.settlementId,
      );
      final model = await remoteDataSource.voidSettlement(data: data);
      return _withAudit(
        model: model,
        actorRole: actorRole,
        action: AuditAction.statusChanged,
        event: DriverSettlementAuditKeys.voided,
        oldValues: oldModel.toAuditValues(),
      );
    });
  }

  Future<Result<DriverSettlement>> _withAudit({
    required DriverSettlementModel model,
    required String actorRole,
    required AuditAction action,
    required String event,
    Map<String, Object?>? oldValues,
  }) async {
    final auditFailure = await _writeAudit(
      companyId: model.companyId,
      actorRole: actorRole,
      model: model,
      action: action,
      event: event,
      oldValues: oldValues,
      newValues: model.toAuditValues(),
      metadata: {
        'audit_event': event,
        'settlement_id': model.id,
        'driver_id': model.driverId,
        'status': model.status.value,
        'period_start': model.periodStart.toIso8601String(),
        'period_end': model.periodEnd.toIso8601String(),
        'closing_driver_balance': model.closingDriverBalance,
        'net_salary_payable': model.netSalaryPayable,
      },
    );

    if (auditFailure != null) {
      return FailureResult(auditFailure);
    }

    return Success(model.toEntity());
  }

  Future<Failure?> _writeAudit({
    required String companyId,
    required String actorRole,
    required DriverSettlementModel model,
    required AuditAction action,
    required String event,
    Map<String, Object?>? oldValues,
    Map<String, Object?>? newValues,
    Map<String, Object?>? metadata,
  }) async {
    final result = await createAuditLogUseCase(
      CreateAuditLogParams(
        data: AuditLogWriteData(
          companyId: companyId,
          actorRole: actorRole,
          module: AuditModule.drivers,
          entityType: AuditEntityType.driver,
          entityId: model.driverId,
          entityDisplayName: DriverSettlementAuditKeys.entityDisplayName,
          action: action,
          description: event,
          oldValues: oldValues,
          newValues: newValues,
          metadata: metadata,
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
