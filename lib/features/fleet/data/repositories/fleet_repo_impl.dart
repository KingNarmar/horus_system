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
import '../../domain/entities/tractor_head.dart';
import '../../domain/entities/tractor_head_write_data.dart';
import '../../domain/entities/trailer_entity.dart';
import '../../domain/entities/trailer_write_data.dart';
import '../../domain/repositories/fleet_repository.dart';
import '../datasources/fleet_remote_data_source.dart';
import '../mappers/fleet_audit_mapper.dart';
import '../mappers/tractor_mapper.dart';
import '../mappers/trailers_mapper.dart';

const _tractorHeadCreatedEvent = 'tractor_head_created';
const _tractorHeadUpdatedEvent = 'tractor_head_updated';
const _tractorHeadDeactivatedEvent = 'tractor_head_deactivated';
const _tractorHeadReactivatedEvent = 'tractor_head_reactivated';
const _trailerCreatedEvent = 'trailer_created';
const _trailerUpdatedEvent = 'trailer_updated';
const _trailerDeactivatedEvent = 'trailer_deactivated';
const _trailerReactivatedEvent = 'trailer_reactivated';

class FleetRepositoryImpl implements FleetRepository {
  final FleetRemoteDataSource remoteDataSource;
  final CreateAuditLogUseCase createAuditLogUseCase;

  const FleetRepositoryImpl({
    required this.remoteDataSource,
    required this.createAuditLogUseCase,
  });

  @override
  Future<Result<List<TractorHead>>> getTractorHeads({
    required String companyId,
  }) {
    return _guard(() async {
      final models = await remoteDataSource.getTractorHeads(
        companyId: companyId.trim(),
      );
      return Success(models.map((model) => model.toEntity()).toList());
    });
  }

  @override
  Future<Result<List<TrailerEntity>>> getTrailers({required String companyId}) {
    return _guard(() async {
      final models = await remoteDataSource.getTrailers(
        companyId: companyId.trim(),
      );
      return Success(models.map((model) => model.toEntity()).toList());
    });
  }

  @override
  Future<Result<TractorHead>> addTractorHead({
    required TractorHeadWriteData data,
    required String actorRole,
  }) {
    return _guard(() async {
      final model = await remoteDataSource.addTractorHead(data: data);
      final auditFailure = await _writeAudit(
        companyId: model.companyId,
        actorRole: actorRole,
        entityType: AuditEntityType.tractorHead,
        entityId: model.id,
        entityDisplayName: model.plateNumber,
        action: AuditAction.created,
        description: _tractorHeadCreatedEvent,
        newValues: model.toAuditValues(),
      );
      if (auditFailure != null) return FailureResult(auditFailure);
      return Success(model.toEntity());
    });
  }

  @override
  Future<Result<TractorHead>> saveTractorHead({
    required String id,
    required TractorHeadWriteData data,
    required String actorRole,
  }) {
    return _guard(() async {
      final oldModel = await remoteDataSource.getTractorHeadById(
        companyId: data.companyId,
        id: id,
      );
      final model = await remoteDataSource.saveTractorHead(id: id, data: data);
      final auditFailure = await _writeAudit(
        companyId: model.companyId,
        actorRole: actorRole,
        entityType: AuditEntityType.tractorHead,
        entityId: model.id,
        entityDisplayName: model.plateNumber,
        action: AuditAction.updated,
        description: _tractorHeadUpdatedEvent,
        oldValues: oldModel.toAuditValues(),
        newValues: model.toAuditValues(),
      );
      if (auditFailure != null) return FailureResult(auditFailure);
      return Success(model.toEntity());
    });
  }

  @override
  Future<Result<TractorHead>> deactivateTractorHead({
    required String companyId,
    required String id,
    required String actorRole,
  }) {
    return _guard(() async {
      final oldModel = await remoteDataSource.getTractorHeadById(
        companyId: companyId,
        id: id,
      );
      final model = await remoteDataSource.deactivateTractorHead(
        companyId: companyId,
        id: id,
      );
      final auditFailure = await _writeAudit(
        companyId: model.companyId,
        actorRole: actorRole,
        entityType: AuditEntityType.tractorHead,
        entityId: model.id,
        entityDisplayName: model.plateNumber,
        action: AuditAction.deactivated,
        description: _tractorHeadDeactivatedEvent,
        oldValues: oldModel.toAuditValues(),
        newValues: model.toAuditValues(),
      );
      if (auditFailure != null) return FailureResult(auditFailure);
      return Success(model.toEntity());
    });
  }

  @override
  Future<Result<TractorHead>> reactivateTractorHead({
    required String companyId,
    required String id,
    required String actorRole,
  }) {
    return _guard(() async {
      final oldModel = await remoteDataSource.getTractorHeadById(
        companyId: companyId,
        id: id,
      );
      final model = await remoteDataSource.reactivateTractorHead(
        companyId: companyId,
        id: id,
      );
      final auditFailure = await _writeAudit(
        companyId: model.companyId,
        actorRole: actorRole,
        entityType: AuditEntityType.tractorHead,
        entityId: model.id,
        entityDisplayName: model.plateNumber,
        action: AuditAction.reactivated,
        description: _tractorHeadReactivatedEvent,
        oldValues: oldModel.toAuditValues(),
        newValues: model.toAuditValues(),
      );
      if (auditFailure != null) return FailureResult(auditFailure);
      return Success(model.toEntity());
    });
  }

  @override
  Future<Result<TrailerEntity>> addTrailer({
    required TrailerWriteData data,
    required String actorRole,
  }) {
    return _guard(() async {
      final model = await remoteDataSource.addTrailer(data: data);
      final auditFailure = await _writeAudit(
        companyId: model.companyId,
        actorRole: actorRole,
        entityType: AuditEntityType.trailer,
        entityId: model.id,
        entityDisplayName: model.plateNumber,
        action: AuditAction.created,
        description: _trailerCreatedEvent,
        newValues: model.toAuditValues(),
      );
      if (auditFailure != null) return FailureResult(auditFailure);
      return Success(model.toEntity());
    });
  }

  @override
  Future<Result<TrailerEntity>> editTrailer({
    required String id,
    required TrailerWriteData data,
    required String actorRole,
  }) {
    return _guard(() async {
      final oldModel = await remoteDataSource.getTrailerById(
        companyId: data.companyId,
        id: id,
      );
      final model = await remoteDataSource.editTrailer(id: id, data: data);
      final auditFailure = await _writeAudit(
        companyId: model.companyId,
        actorRole: actorRole,
        entityType: AuditEntityType.trailer,
        entityId: model.id,
        entityDisplayName: model.plateNumber,
        action: AuditAction.updated,
        description: _trailerUpdatedEvent,
        oldValues: oldModel.toAuditValues(),
        newValues: model.toAuditValues(),
      );
      if (auditFailure != null) return FailureResult(auditFailure);
      return Success(model.toEntity());
    });
  }

  @override
  Future<Result<TrailerEntity>> deactivateTrailer({
    required String companyId,
    required String id,
    required String actorRole,
  }) {
    return _guard(() async {
      final oldModel = await remoteDataSource.getTrailerById(
        companyId: companyId,
        id: id,
      );
      final model = await remoteDataSource.deactivateTrailer(
        companyId: companyId,
        id: id,
      );
      final auditFailure = await _writeAudit(
        companyId: model.companyId,
        actorRole: actorRole,
        entityType: AuditEntityType.trailer,
        entityId: model.id,
        entityDisplayName: model.plateNumber,
        action: AuditAction.deactivated,
        description: _trailerDeactivatedEvent,
        oldValues: oldModel.toAuditValues(),
        newValues: model.toAuditValues(),
      );
      if (auditFailure != null) return FailureResult(auditFailure);
      return Success(model.toEntity());
    });
  }

  @override
  Future<Result<TrailerEntity>> reactivateTrailer({
    required String companyId,
    required String id,
    required String actorRole,
  }) {
    return _guard(() async {
      final oldModel = await remoteDataSource.getTrailerById(
        companyId: companyId,
        id: id,
      );
      final model = await remoteDataSource.reactivateTrailer(
        companyId: companyId,
        id: id,
      );
      final auditFailure = await _writeAudit(
        companyId: model.companyId,
        actorRole: actorRole,
        entityType: AuditEntityType.trailer,
        entityId: model.id,
        entityDisplayName: model.plateNumber,
        action: AuditAction.reactivated,
        description: _trailerReactivatedEvent,
        oldValues: oldModel.toAuditValues(),
        newValues: model.toAuditValues(),
      );
      if (auditFailure != null) return FailureResult(auditFailure);
      return Success(model.toEntity());
    });
  }

  Future<Failure?> _writeAudit({
    required String companyId,
    required String actorRole,
    required AuditEntityType entityType,
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
          module: AuditModule.fleet,
          entityType: entityType,
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
