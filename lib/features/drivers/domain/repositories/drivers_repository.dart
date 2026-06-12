import '../../../../core/utils/result.dart';
import '../entities/driver.dart';
import '../entities/driver_write_data.dart';

abstract class DriversRepository {
  Future<Result<List<Driver>>> getDrivers({required String companyId});

  Future<Result<Driver>> addDriver({
    required DriverWriteData data,
    required String actorRole,
  });

  Future<Result<Driver>> updateDriver({
    required String driverId,
    required DriverWriteData data,
    required String actorRole,
  });

  Future<Result<Driver>> deactivateDriver({
    required String companyId,
    required String driverId,
    required String actorRole,
  });

  Future<Result<Driver>> reactivateDriver({
    required String companyId,
    required String driverId,
    required String actorRole,
  });
}
