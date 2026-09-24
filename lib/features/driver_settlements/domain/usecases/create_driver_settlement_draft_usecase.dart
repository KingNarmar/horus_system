import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/driver_settlement.dart';
import '../entities/driver_settlement_resolved_calculation.dart';
import '../entities/driver_settlement_write_data.dart';
import '../repositories/driver_settlement_money_repository.dart';
import 'driver_settlement_params.dart';
import 'driver_settlement_usecase_validation.dart';
import 'resolve_driver_settlement_calculation_usecase.dart';

final class CreateDriverSettlementDraftUseCase
    implements UseCase<DriverSettlement, CreateDriverSettlementDraftParams> {
  final DriverSettlementMoneyRepository _moneyRepository;
  final ResolveDriverSettlementCalculationUseCase _resolveCalculation;

  const CreateDriverSettlementDraftUseCase({
    required DriverSettlementMoneyRepository moneyRepository,
    required ResolveDriverSettlementCalculationUseCase resolveCalculation,
  }) : _moneyRepository = moneyRepository,
       _resolveCalculation = resolveCalculation;

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

    final result = await _resolveCalculation(params);
    if (result is FailureResult<DriverSettlementResolvedCalculation>) {
      return FailureResult(result.failure);
    }

    final resolved = result.dataOrNull!;
    return _moneyRepository.createMoneyDraft(
      data: DriverSettlementMoneyDraftWriteData(
        companyId: resolved.companyId,
        driverId: resolved.driverId,
        period: resolved.period,
        compensationRevisionId: resolved.compensationRevisionId,
        currencyFractionDigits: resolved.currencyFractionDigits,
        calculation: resolved.calculation,
        items: resolved.items,
        notes: resolved.notes,
      ),
    );
  }
}
