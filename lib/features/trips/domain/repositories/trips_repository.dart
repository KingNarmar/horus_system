import '../../../../core/domain/value_objects/currency_configuration.dart';
import '../../../../core/utils/result.dart';
import '../entities/trip_entity.dart';
import '../entities/trip_form_lookups.dart';
import '../entities/trip_status.dart';
import '../entities/trip_status_history.dart';
import '../entities/trip_write_data.dart';

abstract class TripsRepository {
  Future<Result<List<TripEntity>>> getTrips({
    required String companyId,
    required CurrencyConfiguration? financialConfiguration,
  });

  Future<Result<TripEntity>> getTripDetails({
    required String companyId,
    required String id,
    required CurrencyConfiguration? financialConfiguration,
  });

  Future<Result<TripFormLookups>> getTripFormLookups({
    required String companyId,
    required CurrencyConfiguration? financialConfiguration,
  });

  Future<Result<TripEntity>> createTrip({
    required TripWriteData data,
    required CurrencyConfiguration? financialConfiguration,
  });

  Future<Result<TripEntity>> saveTrip({
    required String id,
    required TripWriteData data,
    required CurrencyConfiguration? financialConfiguration,
  });

  Future<Result<TripEntity>> updateTripStatus({
    required String companyId,
    required String id,
    required TripStatus newStatus,
    required CurrencyConfiguration? financialConfiguration,
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
