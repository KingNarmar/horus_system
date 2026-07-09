import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/driver_settlement.dart';
import '../entities/driver_settlement_period.dart';
import '../entities/driver_settlement_source_snapshot.dart';
import '../entities/driver_settlement_write_data.dart';
import '../repositories/driver_settlements_repository.dart';
import '../services/driver_settlement_calculator.dart';
import 'driver_settlement_params.dart';
import 'driver_settlement_usecase_validation.dart';

class CreateDriverSettlementDraftUseCase
    implements UseCase<DriverSettlement, CreateDriverSettlementDraftParams> {
  final DriverSettlementsRepository _repository;
  final DriverSettlementCalculator _calculator;

  const CreateDriverSettlementDraftUseCase(
    this._repository, {
    DriverSettlementCalculator calculator = const DriverSettlementCalculator(),
  }) : _calculator = calculator;

  @override
  Future<Result<DriverSettlement>> call(
    CreateDriverSettlementDraftParams params,
  ) async {
    final validation =
        DriverSettlementUseCaseValidation.validateCalculationParams(
          params,
          requireManage: true,
        );
    if (validation != null) return FailureResult(validation);

    final context = params.currentCompanyContext;
    final driverId = params.driverId.trim();
    final period = DriverSettlementPeriod(
      start: params.periodStart,
      end: params.periodEnd,
    );

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
    final calculation = _calculator.calculate(
      DriverSettlementUseCaseValidation.calculationInput(
        params: params,
        snapshot: snapshot,
      ),
    );

    return _repository.createDraft(
      actorRole: context.role.name,
      data: DriverSettlementDraftWriteData(
        companyId: context.companyId,
        driverId: driverId,
        period: period,
        calculation: calculation,
        items: snapshot.sourceItems,
        notes: DriverSettlementUseCaseValidation.optional(params.notes),
      ),
    );
  }
}
