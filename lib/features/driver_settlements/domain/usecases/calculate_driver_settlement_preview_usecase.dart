import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/driver_settlement_period.dart';
import '../entities/driver_settlement_preview.dart';
import '../entities/driver_settlement_source_snapshot.dart';
import '../repositories/driver_settlements_repository.dart';
import '../services/driver_settlement_calculator.dart';
import 'driver_settlement_params.dart';
import 'driver_settlement_usecase_validation.dart';

class CalculateDriverSettlementPreviewUseCase
    implements
        UseCase<DriverSettlementPreview, DriverSettlementCalculationParams> {
  final DriverSettlementsRepository _repository;
  final DriverSettlementCalculator _calculator;

  const CalculateDriverSettlementPreviewUseCase(
    this._repository, {
    DriverSettlementCalculator calculator = const DriverSettlementCalculator(),
  }) : _calculator = calculator;

  @override
  Future<Result<DriverSettlementPreview>> call(
    DriverSettlementCalculationParams params,
  ) async {
    final validation =
        DriverSettlementUseCaseValidation.validateCalculationParams(params);
    if (validation != null) return FailureResult(validation);

    final context = params.currentCompanyContext;
    final driverId = params.driverId.trim();
    final period = DriverSettlementPeriod(
      start: params.periodStart,
      end: params.periodEnd,
    );

    final driverValidation =
        await DriverSettlementUseCaseValidation.validateActiveDriver(
          repository: _repository,
          companyId: context.companyId,
          driverId: driverId,
        );
    if (driverValidation != null) return FailureResult(driverValidation);

    final snapshotResult = await _repository.getSettlementSourceSnapshot(
      companyId: context.companyId,
      driverId: driverId,
      period: period,
    );

    if (snapshotResult is FailureResult<DriverSettlementSourceSnapshot>) {
      return FailureResult(snapshotResult.failure);
    }

    final snapshot =
        snapshotResult.dataOrNull ?? const DriverSettlementSourceSnapshot();
    final recoveryValidation =
        DriverSettlementUseCaseValidation.validateBalanceRecovery(
          params: params,
          snapshot: snapshot,
        );
    if (recoveryValidation != null) {
      return FailureResult(recoveryValidation);
    }

    final calculation = _calculator.calculate(
      DriverSettlementUseCaseValidation.calculationInput(
        params: params,
        snapshot: snapshot,
      ),
    );

    return Success(
      DriverSettlementPreview(
        companyId: context.companyId,
        driverId: driverId,
        period: period,
        calculation: calculation,
        items: snapshot.sourceItems,
      ),
    );
  }
}
