import '../../../../core/domain/value_objects/business_date.dart';
import '../../../../core/utils/result.dart';
import '../entities/driver_balance.dart';

abstract class DriverBalanceRepository {
  Future<Result<DriverBalance>> getCanonicalDriverBalance({
    required String companyId,
    required String driverId,
    required BusinessDate beforeExclusive,
    BusinessDate? checkpointBeforeExclusive,
  });
}
