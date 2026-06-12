import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/utils/result.dart';
import '../../../audit/domain/entities/audit_action.dart';
import '../../../audit/domain/entities/audit_entity_type.dart';
import '../../../audit/domain/entities/audit_log_write_data.dart';
import '../../../audit/domain/entities/audit_module.dart';
import '../../../audit/domain/usecases/create_audit_log_usecase.dart';
import '../../domain/entities/driver.dart';
import '../../domain/entities/driver_write_data.dart';
import '../../domain/repositories/drivers_repository.dart';
import '../datasources/drivers_remote_data_source.dart';
import '../mappers/driver_mapper.dart';
import '../models/driver_model.dart';

class DriversRepositoryImpl implements DriversRepository {
  final DriversRemoteDataSource remoteDataSource;
  final CreateAuditLogUseCase createAuditLogUseCase;

  const DriversRepositoryImpl({
    required this.remoteDataSource,
    required this.createAuditLogUseCase,
  });

  @override
  Future<Result<List<Driver>>> getDrivers({required String companyId}) {
    return _guard(() async {
      final normalizedCompanyId = companyId.trim();
      if (normalizedCompanyId.isEmpty) {
        return const FailureResult<List<Driver>>(
          ValidationFailure(code: FailureCodes.validationCompanyIdRequired, message: 'Company id is required.'),
        );
      }

      final models = await remoteDataSource.getDrivers(
        companyId: normalizedCompanyId,
      );
      return Success(models.map((model) => model.toEntity()).toList());
    });
  }

  @override
  Future<Result<Driver>> addDriver({
    required DriverWriteData data,
    required String actorRole,
  }) {
    return _guard(() async {
      final model = await remoteDataSource.addDriver(data: data);
      return _withAudit(
        model: model,
        actorRole: actorRole,
        action: AuditAction.created,
        description: 'Driver created: ${model.fullName}',
      );
    });
  }

  @override
  Future<Result<Driver>> updateDriver({
    required String driverId,
    required DriverWriteData data,
    required String actorRole,
  }) {
    return _guard(() async {
      final oldModel = await remoteDataSource.getDriverById(
        companyId: data.companyId,
        driverId: driverId,
      );
      final model = await remoteDataSource.updateDriver(
        driverId: driverId,
        data: data,
      );
      return _withAudit(
        model: model,
        actorRole: actorRole,
        action: AuditAction.updated,
        description: 'Driver updated: ${model.fullName}',
        oldValues: oldModel.toAuditValues(),
      );
    });
  }

  @override
  Future<Result<Driver>> deactivateDriver({
    required String companyId,
    required String driverId,
    required String actorRole,
  }) {
    return _changeStatus(
      companyId: companyId,
      driverId: driverId,
      actorRole: actorRole,
      action: AuditAction.deactivated,
      mutate: remoteDataSource.deactivateDriver,
    );
  }

  @override
  Future<Result<Driver>> reactivateDriver({
    required String companyId,
    required String driverId,
    required String actorRole,
  }) {
    return _changeStatus(
      companyId: companyId,
      driverId: driverId,
      actorRole: actorRole,
      action: AuditAction.reactivated,
      mutate: remoteDataSource.reactivateDriver,
    );
  }

  Future<Result<Driver>> _changeStatus({
    required String companyId,
    required String driverId,
    required String actorRole,
    required AuditAction action,
    required Future<DriverModel> Function({
      required String companyId,
      required String driverId,
    }) mutate,
  }) {
    return _guard(() async {
      final oldModel = await remoteDataSource.getDriverById(
        companyId: companyId,
        driverId: driverId,
      );
      final model = await mutate(companyId: companyId, driverId: driverId);
      final actionText = action.value.replaceAll('_', ' ');
      return _withAudit(
        model: model,
        actorRole: actorRole,
        action: action,
        description: 'Driver $actionText: ${model.fullName}',
        oldValues: oldModel.toAuditValues(),
      );
    });
  }

  Future<Result<Driver>> _withAudit({
    required DriverModel model,
    required String actorRole,
    required AuditAction action,
    required String description,
    Map<String, Object?>? oldValues,
  }) async {
    final auditFailure = await _writeDriverAudit(
      companyId: model.companyId,
      actorRole: actorRole,
      entityId: model.id,
      entityDisplayName: model.fullName,
      action: action,
      description: description,
      oldValues: oldValues,
      newValues: model.toAuditValues(),
    );

    if (auditFailure != null) return FailureResult(auditFailure);
    return Success(model.toEntity());
  }

  Future<Failure?> _writeDriverAudit({
    required String companyId,
    required String actorRole,
    required String entityId,
    required String entityDisplayName,
    required AuditAction action,
    required String description,
    Map<String, Object?>? oldValues,
    Map<String, Object?>? newValues,
  }) async {
    final result = await createAuditLogUseCase(
      CreateAuditLogParams(
        data: AuditLogWriteData(
          companyId: companyId,
          actorRole: actorRole,
          module: AuditModule.drivers,
          entityType: AuditEntityType.driver,
          entityId: entityId,
          entityDisplayName: entityDisplayName,
          action: action,
          description: description,
          oldValues: oldValues,
          newValues: newValues,
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
        ServerFailure(code: error.code ?? FailureCodes.serverError, message: error.message),
      );
    } catch (error) {
      return FailureResult(UnexpectedFailure(message: error.toString()));
    }
  }
}
