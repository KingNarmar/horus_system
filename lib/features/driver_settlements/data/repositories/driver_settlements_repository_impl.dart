import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../../../core/domain/value_objects/currency_configuration.dart';
import '../../../../core/utils/result.dart';
import '../../../driver_finance/domain/entities/driver_balance.dart';
import '../../../driver_finance/domain/repositories/driver_balance_repository.dart';
import '../../domain/entities/driver_settlement.dart';
import '../../domain/entities/driver_settlement_driver_option.dart';
import '../../domain/entities/driver_settlement_money_source_snapshot.dart';
import '../../domain/entities/driver_settlement_period.dart';
import '../../domain/entities/driver_settlement_source_snapshot.dart';
import '../../domain/entities/driver_settlement_write_data.dart';
import '../../domain/repositories/driver_settlement_money_repository.dart';
import '../../domain/repositories/driver_settlements_repository.dart';
import '../datasources/driver_settlement_money_remote_data_source.dart';
import '../datasources/driver_settlements_remote_data_source.dart';
import '../mappers/driver_settlement_driver_option_mapper.dart';
import '../mappers/driver_settlement_mapper.dart';
import 'driver_settlement_repository_failure_mapper.dart';

class DriverSettlementsRepositoryImpl
    implements DriverSettlementsRepository, DriverSettlementMoneyRepository {
  final DriverSettlementsRemoteDataSource remoteDataSource;
  final DriverSettlementMoneyRemoteDataSource moneyRemoteDataSource;
  final DriverBalanceRepository driverBalanceRepository;
  final DriverSettlementRepositoryFailureMapper _failureMapper;

  const DriverSettlementsRepositoryImpl({
    required this.remoteDataSource,
    required this.moneyRemoteDataSource,
    required this.driverBalanceRepository,
  }) : _failureMapper = const DriverSettlementRepositoryFailureMapper();

  @override
  Future<Result<List<DriverSettlement>>> getDriverSettlements({
    required String companyId,
    String? driverId,
    bool includeVoided = false,
  }) {
    return _guard(() async {
      final models = await remoteDataSource.getDriverSettlements(
        companyId: companyId,
        driverId: driverId,
        includeVoided: includeVoided,
      );
      return Success(models.map((model) => model.toEntity()).toList());
    });
  }

  @override
  Future<Result<List<DriverSettlementDriverOption>>> getDriverOptions({
    required String companyId,
  }) {
    return _guard(() async {
      final models = await remoteDataSource.getDriverOptions(
        companyId: companyId,
      );
      return Success(models.map((model) => model.toEntity()).toList());
    });
  }

  @override
  Future<Result<DriverSettlementDriverOption?>> getDriverOptionById({
    required String companyId,
    required String driverId,
  }) {
    return _guard(() async {
      final model = await remoteDataSource.getDriverOptionById(
        companyId: companyId,
        driverId: driverId,
      );
      return Success(model?.toEntity());
    });
  }

  @override
  Future<Result<DriverSettlement>> getDriverSettlementById({
    required String companyId,
    required String settlementId,
  }) {
    return _guard(() async {
      final model = await remoteDataSource.getDriverSettlementById(
        companyId: companyId,
        settlementId: settlementId,
      );
      return Success(model.toEntity());
    });
  }

  @override
  Future<Result<DriverSettlementSourceSnapshot>> getSettlementSourceSnapshot({
    required String companyId,
    required String driverId,
    required DriverSettlementPeriod period,
  }) {
    return _guard(() async {
      final openingResult = await driverBalanceRepository
          .getCanonicalDriverBalance(
            companyId: companyId,
            driverId: driverId,
            beforeExclusive: period.start,
            checkpointBeforeExclusive: period.start,
          );
      if (openingResult is FailureResult<DriverBalance>) {
        return FailureResult<DriverSettlementSourceSnapshot>(
          openingResult.failure,
        );
      }

      final snapshot = await remoteDataSource.getSettlementSourceSnapshot(
        companyId: companyId,
        driverId: driverId,
        period: period,
      );
      final openingBalance = openingResult.dataOrNull?.netBalance ?? 0;
      return Success(snapshot.withOpeningDriverBalance(openingBalance));
    });
  }

  @override
  Future<Result<DriverSettlementMoneySourceSnapshot>>
  getSettlementMoneySourceSnapshot({
    required String companyId,
    required String driverId,
    required DriverSettlementPeriod period,
    required CurrencyConfiguration currencyConfiguration,
  }) {
    return _guard(() async {
      final snapshot = await moneyRemoteDataSource
          .getSettlementMoneySourceSnapshot(
            companyId: companyId,
            driverId: driverId,
            period: period,
            currencyConfiguration: currencyConfiguration,
          );
      return Success(snapshot);
    });
  }

  @override
  Future<Result<DriverSettlement>> createDraft({
    required DriverSettlementDraftWriteData data,
    required String actorRole,
  }) {
    return _guard(() async {
      final model = await remoteDataSource.createDraft(data: data);
      return Success(model.toEntity());
    });
  }

  @override
  Future<Result<DriverSettlement>> createMoneyDraft({
    required DriverSettlementMoneyDraftWriteData data,
    required String actorRole,
  }) {
    return _guard(() async {
      final model = await moneyRemoteDataSource.createMoneyDraft(data: data);
      return Success(model.toEntity());
    });
  }

  @override
  Future<Result<DriverSettlement>> finalizeSettlement({
    required DriverSettlementFinalizeData data,
    required String actorRole,
  }) {
    return _guard(() async {
      final model = await remoteDataSource.finalizeSettlement(data: data);
      return Success(model.toEntity());
    });
  }

  @override
  Future<Result<DriverSettlement>> voidSettlement({
    required DriverSettlementVoidData data,
    required String actorRole,
  }) {
    return _guard(() async {
      final model = await remoteDataSource.voidSettlement(data: data);
      return Success(model.toEntity());
    });
  }

  Future<Result<T>> _guard<T>(Future<Result<T>> Function() action) async {
    try {
      return await action();
    } on PostgrestException catch (error) {
      return FailureResult(_failureMapper.fromPostgrest(error));
    } catch (error) {
      return FailureResult(_failureMapper.fromUnexpected(error));
    }
  }
}
