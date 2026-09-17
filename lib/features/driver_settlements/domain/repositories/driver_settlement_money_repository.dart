import '../../../../core/domain/value_objects/currency_configuration.dart';
import '../../../../core/utils/result.dart';
import '../entities/driver_settlement.dart';
import '../entities/driver_settlement_money_source_snapshot.dart';
import '../entities/driver_settlement_period.dart';
import '../entities/driver_settlement_write_data.dart';

abstract class DriverSettlementMoneyRepository {
  Future<Result<DriverSettlementMoneySourceSnapshot>>
  getSettlementMoneySourceSnapshot({
    required String companyId,
    required String driverId,
    required DriverSettlementPeriod period,
    required CurrencyConfiguration currencyConfiguration,
  });

  Future<Result<DriverSettlement>> createMoneyDraft({
    required DriverSettlementMoneyDraftWriteData data,
    required String actorRole,
  });
}
