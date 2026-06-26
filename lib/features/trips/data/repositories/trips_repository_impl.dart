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
import '../../domain/entities/trip_entity.dart';
import '../../domain/entities/trip_form_lookups.dart';
import '../../domain/entities/trip_status.dart';
import '../../domain/entities/trip_status_history.dart';
import '../../domain/entities/trip_write_data.dart';
import '../../domain/repositories/trips_repository.dart';
import '../datasources/trips_remote_data_source.dart';
import '../mappers/trip_mapper.dart';
import '../models/trip_model.dart';

class TripsRepositoryImpl implements TripsRepository {
  final TripsRemoteDataSource remoteDataSource;
  final CreateAuditLogUseCase createAuditLogUseCase;

  const TripsRepositoryImpl({
    required this.remoteDataSource,
    required this.createAuditLogUseCase,
  });

  @override
  Future<Result<List<TripEntity>>> getTrips({required String companyId}) {
    return _guard(() async {
      final models = await remoteDataSource.getTrips(companyId: companyId);
      return Success(models.map((model) => model.toEntity()).toList());
    });
  }

  @override
  Future<Result<TripEntity>> getTripDetails({
    required String companyId,
    required String id,
  }) {
    return _guard(() async {
      final model = await remoteDataSource.getTripById(
        companyId: companyId,
        id: id,
      );

      return Success(model.toEntity());
    });
  }

  @override
  Future<Result<TripFormLookups>> getTripFormLookups({
    required String companyId,
  }) {
    return _guard(() async {
      final lookups = await remoteDataSource.getTripFormLookups(
        companyId: companyId,
      );

      return Success(lookups);
    });
  }

  @override
  Future<Result<TripEntity>> createTrip({
    required TripWriteData data,
    required String actorRole,
  }) {
    return _guard(() async {
      final model = await remoteDataSource.createTrip(data: data);
      final status = TripStatusX.fromValue(model.status);

      await remoteDataSource.addTripStatusHistory(
        companyId: model.companyId,
        tripId: model.id,
        oldStatus: null,
        newStatus: status,
        actorRole: actorRole,
      );

      final auditFailure = await _writeAudit(
        companyId: model.companyId,
        actorRole: actorRole,
        entityId: model.id,
        entityDisplayName: model.displayName,
        action: AuditAction.created,
        description: 'Trip created: ${model.displayName}',
        newValues: model.toAuditValues(),
      );

      if (auditFailure != null) {
        return FailureResult<TripEntity>(auditFailure);
      }

      return Success(model.toEntity());
    });
  }

  @override
  Future<Result<TripEntity>> saveTrip({
    required String id,
    required TripWriteData data,
    required String actorRole,
  }) {
    return _guard(() async {
      final oldModel = await remoteDataSource.getTripById(
        companyId: data.companyId,
        id: id,
      );

      final model = await remoteDataSource.saveTrip(id: id, data: data);

      final auditFailure = await _writeAudit(
        companyId: model.companyId,
        actorRole: actorRole,
        entityId: model.id,
        entityDisplayName: model.displayName,
        action: AuditAction.updated,
        description: 'Trip updated: ${model.displayName}',
        oldValues: oldModel.toAuditValues(),
        newValues: model.toAuditValues(),
      );

      if (auditFailure != null) {
        return FailureResult<TripEntity>(auditFailure);
      }

      return Success(model.toEntity());
    });
  }

  @override
  Future<Result<TripEntity>> updateTripStatus({
    required String companyId,
    required String id,
    required TripStatus newStatus,
    required String actorRole,
    String? notes,
  }) {
    return _guard(() async {
      final oldModel = await remoteDataSource.getTripById(
        companyId: companyId,
        id: id,
      );

      final oldStatus = TripStatusX.fromValue(oldModel.status);

      final model = await remoteDataSource.updateTripStatus(
        companyId: companyId,
        id: id,
        newStatus: newStatus,
      );

      await remoteDataSource.addTripStatusHistory(
        companyId: model.companyId,
        tripId: model.id,
        oldStatus: oldStatus,
        newStatus: newStatus,
        actorRole: actorRole,
        notes: notes,
      );

      final auditFailure = await _writeAudit(
        companyId: model.companyId,
        actorRole: actorRole,
        entityId: model.id,
        entityDisplayName: model.displayName,
        action: AuditAction.statusChanged,
        description:
            'Trip status changed: ${model.displayName} (${oldStatus.value} -> ${newStatus.value})',
        oldValues: oldModel.toAuditValues(),
        newValues: model.toAuditValues(),
        metadata: {
          'old_status': oldStatus.value,
          'new_status': newStatus.value,
          'notes': notes,
        },
      );

      if (auditFailure != null) {
        return FailureResult<TripEntity>(auditFailure);
      }

      return Success(model.toEntity());
    });
  }

  @override
  Future<Result<List<TripStatusHistory>>> getTripStatusHistory({
    required String companyId,
    required String tripId,
  }) {
    return _guard(() async {
      final models = await remoteDataSource.getTripStatusHistory(
        companyId: companyId,
        tripId: tripId,
      );

      return Success(models.map((model) => model.toEntity()).toList());
    });
  }

  @override
  Future<Result<bool>> hasOpenTripForVehicle({
    required String companyId,
    String? tractorHeadId,
    String? trailerId,
    String? excludingTripId,
  }) {
    return _guard(() async {
      final hasOpenTrip = await remoteDataSource.hasOpenTripForVehicle(
        companyId: companyId,
        tractorHeadId: tractorHeadId,
        trailerId: trailerId,
        excludingTripId: excludingTripId,
      );

      return Success(hasOpenTrip);
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
    Map<String, Object?>? metadata,
  }) async {
    final result = await createAuditLogUseCase(
      CreateAuditLogParams(
        data: AuditLogWriteData(
          companyId: companyId,
          actorRole: actorRole,
          module: AuditModule.trips,
          entityType: AuditEntityType.trip,
          entityId: entityId,
          entityDisplayName: entityDisplayName,
          action: action,
          description: description,
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

extension _TripModelDisplayName on TripModel {
  String get displayName {
    final loadingOrder = loadingOrderNumber?.trim();
    if (loadingOrder != null && loadingOrder.isNotEmpty) {
      return loadingOrder;
    }

    final waybill = waybillNumber?.trim();
    if (waybill != null && waybill.isNotEmpty) {
      return waybill;
    }

    final customer = customerName?.trim();
    final route = routeName?.trim();

    if (customer != null &&
        customer.isNotEmpty &&
        route != null &&
        route.isNotEmpty) {
      return '$customer - $route';
    }

    return id;
  }
}
