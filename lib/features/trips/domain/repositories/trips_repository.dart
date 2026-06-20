import 'package:horus_system/features/trips/domain/entities/trip_status_history.dart';

import '../../../../core/utils/result.dart';
import '../entities/trip_entity.dart';
import '../entities/trip_status.dart';
import '../entities/trip_write_data.dart';

abstract class TripsRepository {
  Future<Result<List<TripEntity>>> getTrips({required String companyId});

  Future<Result<TripEntity>> getTripDetails({
    required String companyId,
    required String id,
  });

  Future<Result<TripEntity>> createTrip({
    required TripWriteData data,
    required String actorRole,
  });

  Future<Result<TripEntity>> saveTrip({
    required String id,
    required TripWriteData data,
    required String actorRole,
  });

  Future<Result<TripEntity>> updateTripStatus({
    required String companyId,
    required String id,
    required TripStatus newStatus,
    required String actorRole,
    String? notes,
  });

  Future<Result<List<TripStatusHistory>>> getTripStatusHistory({
    required String companyId,
    required String tripId,
  });

  Future<Result<bool>> hasOpenTripForVehicle({
    required String companyId,
    String? tractorHeadId,
    String? trailerId,
    String? excludingTripId,
  });
}
