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
import '../../domain/entities/route_entity.dart';
import '../../domain/entities/route_write_data.dart';
import '../../domain/repositories/routes_repository.dart';
import '../datasources/routes_remote_data_source.dart';
import '../mappers/route_mapper.dart';
import '../models/route_model.dart';

class RoutesRepositoryImpl implements RoutesRepository {
  final RoutesRemoteDataSource remoteDataSource;
  final CreateAuditLogUseCase createAuditLogUseCase;

  const RoutesRepositoryImpl({
    required this.remoteDataSource,
    required this.createAuditLogUseCase,
  });

  @override
  Future<Result<List<RouteEntity>>> getRoutes({required String companyId}) {
    return _guard(() async {
      final models = await remoteDataSource.getRoutes(companyId: companyId);
      return Success(models.map((model) => model.toEntity()).toList());
    });
  }

  @override
  Future<Result<RouteEntity>> addRoute({
    required RouteWriteData data,
    required String actorRole,
  }) {
    return _guard(() async {
      final model = await remoteDataSource.addRoute(data: data);

      final auditFailure = await _writeAudit(
        companyId: model.companyId,
        actorRole: actorRole,
        entityId: model.id,
        entityDisplayName: model.displayName,
        action: AuditAction.created,
        description: 'Route created: ${model.displayName}',
        newValues: model.toAuditValues(),
      );

      if (auditFailure != null) return FailureResult(auditFailure);
      return Success(model.toEntity());
    });
  }

  @override
  Future<Result<RouteEntity>> saveRoute({
    required String id,
    required RouteWriteData data,
    required String actorRole,
  }) {
    return _guard(() async {
      final oldModel = await remoteDataSource.getRouteById(
        companyId: data.companyId,
        id: id,
      );

      final model = await remoteDataSource.saveRoute(id: id, data: data);

      final auditFailure = await _writeAudit(
        companyId: model.companyId,
        actorRole: actorRole,
        entityId: model.id,
        entityDisplayName: model.displayName,
        action: AuditAction.updated,
        description: 'Route updated: ${model.displayName}',
        oldValues: oldModel.toAuditValues(),
        newValues: model.toAuditValues(),
      );

      if (auditFailure != null) return FailureResult(auditFailure);
      return Success(model.toEntity());
    });
  }

  @override
  Future<Result<RouteEntity>> deactivateRoute({
    required String companyId,
    required String id,
    required String actorRole,
  }) {
    return _changeActiveState(
      companyId: companyId,
      id: id,
      actorRole: actorRole,
      action: AuditAction.deactivated,
      descriptionVerb: 'deactivated',
      change: remoteDataSource.deactivateRoute,
    );
  }

  @override
  Future<Result<RouteEntity>> reactivateRoute({
    required String companyId,
    required String id,
    required String actorRole,
  }) {
    return _changeActiveState(
      companyId: companyId,
      id: id,
      actorRole: actorRole,
      action: AuditAction.reactivated,
      descriptionVerb: 'reactivated',
      change: remoteDataSource.reactivateRoute,
    );
  }

  Future<Result<RouteEntity>> _changeActiveState({
    required String companyId,
    required String id,
    required String actorRole,
    required AuditAction action,
    required String descriptionVerb,
    required Future<RouteModel> Function({
      required String companyId,
      required String id,
    })
    change,
  }) {
    return _guard(() async {
      final oldModel = await remoteDataSource.getRouteById(
        companyId: companyId,
        id: id,
      );

      final model = await change(companyId: companyId, id: id);

      final auditFailure = await _writeAudit(
        companyId: model.companyId,
        actorRole: actorRole,
        entityId: model.id,
        entityDisplayName: model.displayName,
        action: action,
        description: 'Route $descriptionVerb: ${model.displayName}',
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
          module: AuditModule.routes,
          entityType: AuditEntityType.route,
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

extension _RouteModelDisplayName on RouteModel {
  String get displayName => '$loadingLocation → $unloadingLocation';
}
