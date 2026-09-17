import '../../../../core/domain/value_objects/currency_configuration.dart';
import '../../domain/entities/driver_settlement_money_source_snapshot.dart';
import '../../domain/entities/driver_settlement_period.dart';
import '../../domain/entities/driver_settlement_write_data.dart';
import '../models/driver_settlement_model.dart';

abstract class DriverSettlementMoneyRemoteDataSource {
  Future<DriverSettlementMoneySourceSnapshot> getSettlementMoneySourceSnapshot({
    required String companyId,
    required String driverId,
    required DriverSettlementPeriod period,
    required CurrencyConfiguration currencyConfiguration,
  });

  Future<DriverSettlementModel> createMoneyDraft({
    required DriverSettlementMoneyDraftWriteData data,
  });
}
