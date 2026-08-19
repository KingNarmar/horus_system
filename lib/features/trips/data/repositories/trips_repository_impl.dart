import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../../../core/utils/result.dart';
import '../../../audit/domain/usecases/create_audit_log_usecase.dart';
import '../../domain/entities/trip_entity.dart';
import '../../domain/entities/trip_form_lookups.dart';
import '../../domain/entities/trip_status.dart';
import '../../domain/entities/trip_status_history.dart';
import '../../domain/entities/trip_write_data.dart';
import '../../domain/repositories/trips_repository.dart';
import '../datasources/trips_remote_data_source.dart';
import '../mappers/trip_mapper.dart';
import 'trip_repository_audit_writer.dart';
import 'trip_repository_failure_mapper.dart';

class TripsRepositoryImpl implements TripsRepository {
  final TripsRemoteDataSource remoteDataSource;
  final CreateAuditLogUseCase createAuditLogUseCase;
  final TripRepositoryFailureMapper _failureMapper;

  const TripsRepositoryImpl({
    required this.remoteDataSource,
    required this.createAuditLogUseCase,
  }) : _failureMapper = const TripRepositoryFailureMapper();

  TripRepositoryAuditWriter get _auditWriter {
    return TripRepositoryAuditWriter(createAuditLogUseCase);
  }

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

      final auditFailure = await _auditWriter.writeCreated(
        model: model,
        actorRole: actorRole,
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

      final auditFailure = await _auditWriter.writeUpdated(
        oldModel: oldModel,
        model: model,
        actorRole: actorRole,
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

      final auditFailure = await _auditWriter.writeStatusChanged(
        oldModel: oldModel,
        model: model,
        oldStatus: oldStatus,
        newStatus: newStatus,
        actorRole: actorRole,
        notes: notes,
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

  Future<Result<T>> _guard<T>(Future<Result<T>> Function() action) async {
    try {
      return await action();
    } on PostgrestException catch (error) {
      return FailureResult(_failureMapper.fromPostgrest(error));
    } catch (error) {
      return FailureResult(_failureMapper.fromUnexpected(error));
    }
  }
}
