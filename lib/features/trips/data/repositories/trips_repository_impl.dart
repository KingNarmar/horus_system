import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../../../core/domain/value_objects/currency_configuration.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/trip_entity.dart';
import '../../domain/entities/trip_form_lookups.dart';
import '../../domain/entities/trip_status.dart';
import '../../domain/entities/trip_status_history.dart';
import '../../domain/entities/trip_write_data.dart';
import '../../domain/repositories/trips_repository.dart';
import '../datasources/trips_remote_data_source.dart';
import '../mappers/trip_mapper.dart';
import 'trip_repository_failure_mapper.dart';

class TripsRepositoryImpl implements TripsRepository {
  final TripsRemoteDataSource remoteDataSource;
  final TripRepositoryFailureMapper _failureMapper;

  const TripsRepositoryImpl({required this.remoteDataSource})
    : _failureMapper = const TripRepositoryFailureMapper();

  @override
  Future<Result<List<TripEntity>>> getTrips({
    required String companyId,
    required CurrencyConfiguration? financialConfiguration,
  }) {
    return _guard(() async {
      final models = await remoteDataSource.getTrips(companyId: companyId);
      return Success(
        models
            .map(
              (model) => model.toEntity(
                financialConfiguration: financialConfiguration,
              ),
            )
            .toList(),
      );
    });
  }

  @override
  Future<Result<TripEntity>> getTripDetails({
    required String companyId,
    required String id,
    required CurrencyConfiguration? financialConfiguration,
  }) {
    return _guard(() async {
      final model = await remoteDataSource.getTripById(
        companyId: companyId,
        id: id,
      );

      return Success(
        model.toEntity(financialConfiguration: financialConfiguration),
      );
    });
  }

  @override
  Future<Result<TripFormLookups>> getTripFormLookups({
    required String companyId,
    required CurrencyConfiguration? financialConfiguration,
  }) {
    return _guard(() async {
      final lookups = await remoteDataSource.getTripFormLookups(
        companyId: companyId,
      );

      return Success(
        lookups.toEntity(financialConfiguration: financialConfiguration),
      );
    });
  }

  @override
  Future<Result<TripEntity>> createTrip({
    required TripWriteData data,
    required CurrencyConfiguration? financialConfiguration,
  }) {
    return _guard(() async {
      final model = await remoteDataSource.createTrip(
        data: data,
        financialConfiguration: financialConfiguration,
      );

      return Success(
        model.toEntity(financialConfiguration: financialConfiguration),
      );
    });
  }

  @override
  Future<Result<TripEntity>> saveTrip({
    required String id,
    required TripWriteData data,
    required CurrencyConfiguration? financialConfiguration,
  }) {
    return _guard(() async {
      final model = await remoteDataSource.saveTrip(
        id: id,
        data: data,
        financialConfiguration: financialConfiguration,
      );

      return Success(
        model.toEntity(financialConfiguration: financialConfiguration),
      );
    });
  }

  @override
  Future<Result<TripEntity>> updateTripStatus({
    required String companyId,
    required String id,
    required TripStatus newStatus,
    required CurrencyConfiguration? financialConfiguration,
    String? notes,
  }) {
    return _guard(() async {
      final model = await remoteDataSource.updateTripStatus(
        companyId: companyId,
        id: id,
        newStatus: newStatus,
        notes: notes,
      );

      return Success(
        model.toEntity(financialConfiguration: financialConfiguration),
      );
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
