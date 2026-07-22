import '../../../../core/utils/result.dart';
import '../entities/driver_balance.dart';

abstract class DriverBalanceRepository {
  Future<Result<DriverBalance>> getCanonicalDriverBalance({
    required String companyId,
    required String driverId,
    required DateTime beforeExclusive,
    DateTime? checkpointBeforeExclusive,
  });
}
