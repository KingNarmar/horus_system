import '../../../../core/utils/result.dart';
import '../entities/driver_settlement.dart';
import '../entities/driver_settlement_driver_option.dart';
import '../entities/driver_settlement_period.dart';
import '../entities/driver_settlement_source_snapshot.dart';
import '../entities/driver_settlement_write_data.dart';

abstract class DriverSettlementsRepository {
  Future<Result<List<DriverSettlement>>> getDriverSettlements({
    required String companyId,
    String? driverId,
    bool includeVoided = false,
  });

  Future<Result<List<DriverSettlementDriverOption>>> getDriverOptions({
    required String companyId,
  });

  Future<Result<DriverSettlement>> getDriverSettlementById({
    required String companyId,
    required String settlementId,
  });

  Future<Result<DriverSettlementSourceSnapshot>> getSettlementSourceSnapshot({
    required String companyId,
    required String driverId,
    required DriverSettlementPeriod period,
  });

  Future<Result<DriverSettlement>> createDraft({
    required DriverSettlementDraftWriteData data,
    required String actorRole,
  });

  Future<Result<DriverSettlement>> finalizeSettlement({
    required DriverSettlementFinalizeData data,
    required String actorRole,
  });

  Future<Result<DriverSettlement>> voidSettlement({
    required DriverSettlementVoidData data,
    required String actorRole,
  });
}
