import '../../../../core/utils/result.dart';
import '../entities/driver_finance_trip_option.dart';
import '../entities/driver_financial_movement.dart';
import '../entities/driver_financial_movement_write_data.dart';

abstract class DriverFinanceRepository {
  Future<Result<List<DriverFinancialMovement>>> getDriverMovements({
    required String companyId,
    required String driverId,
  });

  Future<Result<List<DriverFinanceTripOption>>> getDriverTripOptions({
    required String companyId,
    required String driverId,
  });

  Future<Result<DriverFinancialMovement>> addDriverMovement({
    required DriverFinancialMovementWriteData data,
    required String actorRole,
  });
}
