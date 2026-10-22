import '../../../../core/domain/value_objects/business_date.dart';
import '../../../../core/domain/value_objects/currency_code.dart';
import '../../../../core/utils/result.dart';
import '../entities/driver_balance_activity.dart';

abstract class DriverBalanceActivityRepository {
  Future<Result<DriverBalanceActivity>> getDriverBalanceActivity({
    required String companyId,
    required String driverId,
    required CurrencyCode currency,
    required int currencyFractionDigits,
    required BusinessDate beforeExclusive,
    BusinessDate? checkpointBeforeExclusive,
  });
}
