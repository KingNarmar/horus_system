import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/driver_settlement_preview.dart';
import '../entities/driver_settlement_resolved_calculation.dart';
import 'driver_settlement_params.dart';
import 'resolve_driver_settlement_calculation_usecase.dart';

final class CalculateDriverSettlementPreviewUseCase
    implements
        UseCase<DriverSettlementPreview, DriverSettlementCalculationParams> {
  final ResolveDriverSettlementCalculationUseCase _resolveCalculation;

  const CalculateDriverSettlementPreviewUseCase(this._resolveCalculation);

  @override
  Future<Result<DriverSettlementPreview>> call(
    DriverSettlementCalculationParams params,
  ) async {
    final result = await _resolveCalculation(params);
    if (result is FailureResult<DriverSettlementResolvedCalculation>) {
      return FailureResult(result.failure);
    }

    final resolved = result.dataOrNull!;
    return Success(
      DriverSettlementPreview(
        companyId: resolved.companyId,
        driverId: resolved.driverId,
        period: resolved.period,
        compensationRevisionId: resolved.compensationRevisionId,
        currencyFractionDigits: resolved.currencyFractionDigits,
        calculation: resolved.calculation,
        items: resolved.items,
      ),
    );
  }
}
