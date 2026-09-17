import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../../../driver_finance/domain/entities/driver_money_balance.dart';
import '../../../driver_finance/domain/usecases/get_canonical_driver_balance_usecase.dart';
import '../../../driver_finance/domain/usecases/get_canonical_driver_money_balance_usecase.dart';
import '../../../drivers/domain/entities/driver_compensation_revision.dart';
import '../../../drivers/domain/usecases/resolve_driver_compensation_for_period_usecase.dart';
import '../entities/driver_settlement_item_direction.dart';
import '../entities/driver_settlement_item_source_type.dart';
import '../entities/driver_settlement_money_item.dart';
import '../entities/driver_settlement_money_source_snapshot.dart';
import '../entities/driver_settlement_period.dart';
import '../entities/driver_settlement_resolved_calculation.dart';
import '../entities/driver_settlement_resolved_money_inputs.dart';
import '../repositories/driver_settlement_money_repository.dart';
import '../repositories/driver_settlements_repository.dart';
import '../services/driver_settlement_calculator.dart';
import '../services/driver_settlement_money_input_resolver.dart';
import 'driver_settlement_params.dart';
import 'driver_settlement_usecase_validation.dart';

final class ResolveDriverSettlementCalculationUseCase
    implements
        UseCase<
          DriverSettlementResolvedCalculation,
          DriverSettlementCalculationParams
        > {
  static const _manualDeductionLabelKey = 'driver_settlement_item_deduction';
  static const _manualAdjustmentKindKey = 'adjustment_kind';
  static const _settlementDeductionKind = 'settlement_deduction';

  final DriverSettlementsRepository _repository;
  final DriverSettlementMoneyRepository _moneyRepository;
  final ResolveDriverCompensationForPeriodUseCase _resolveCompensation;
  final GetCanonicalDriverMoneyBalanceUseCase _getCanonicalMoneyBalance;
  final DriverSettlementMoneyInputResolver _moneyInputResolver;
  final DriverSettlementCalculator _calculator;

  const ResolveDriverSettlementCalculationUseCase({
    required DriverSettlementsRepository repository,
    required DriverSettlementMoneyRepository moneyRepository,
    required ResolveDriverCompensationForPeriodUseCase resolveCompensation,
    required GetCanonicalDriverMoneyBalanceUseCase getCanonicalMoneyBalance,
    DriverSettlementMoneyInputResolver moneyInputResolver =
        const DriverSettlementMoneyInputResolver(),
    DriverSettlementCalculator calculator = const DriverSettlementCalculator(),
  }) : _repository = repository,
       _moneyRepository = moneyRepository,
       _resolveCompensation = resolveCompensation,
       _getCanonicalMoneyBalance = getCanonicalMoneyBalance,
       _moneyInputResolver = moneyInputResolver,
       _calculator = calculator;

  @override
  Future<Result<DriverSettlementResolvedCalculation>> call(
    DriverSettlementCalculationParams params,
  ) async {
    final validationFailure =
        DriverSettlementUseCaseValidation.validateCalculationParams(params);
    if (validationFailure != null) return FailureResult(validationFailure);

    final context = params.currentCompanyContext;
    final driverId = params.driverId.trim();
    final period = DriverSettlementPeriod(
      start: params.periodStart,
      end: params.periodEnd,
    );

    final driverFailure =
        await DriverSettlementUseCaseValidation.validateActiveDriver(
          repository: _repository,
          companyId: context.companyId,
          driverId: driverId,
        );
    if (driverFailure != null) return FailureResult(driverFailure);

    final compensationResult = await _resolveCompensation(
      ResolveDriverCompensationForPeriodParams(
        currentCompanyContext: context,
        driverId: driverId,
        periodStart: period.start,
        periodEnd: period.end,
      ),
    );
    if (compensationResult is FailureResult<DriverCompensationRevision>) {
      return FailureResult(compensationResult.failure);
    }
    final compensation = compensationResult.dataOrNull!;

    final inputsResult = _moneyInputResolver.resolve(
      params: params,
      compensationRevision: compensation,
    );
    if (inputsResult is FailureResult<DriverSettlementResolvedMoneyInputs>) {
      return FailureResult(inputsResult.failure);
    }
    final resolvedInputs = inputsResult.dataOrNull!;

    final openingResult = await _getCanonicalMoneyBalance(
      GetCanonicalDriverBalanceParams(
        currentCompanyContext: context,
        driverId: driverId,
        beforeExclusive: period.start,
        checkpointBeforeExclusive: period.start,
      ),
    );
    if (openingResult is FailureResult<DriverMoneyBalance>) {
      return FailureResult(openingResult.failure);
    }
    final openingBalance = openingResult.dataOrNull!.netBalance;

    final sourceResult = await _moneyRepository
        .getSettlementMoneySourceSnapshot(
          companyId: context.companyId,
          driverId: driverId,
          period: period,
          currencyConfiguration: resolvedInputs.currencyConfiguration,
        );
    if (sourceResult is FailureResult<DriverSettlementMoneySourceSnapshot>) {
      return FailureResult(sourceResult.failure);
    }
    final snapshot = sourceResult.dataOrNull!.withOpeningDriverBalance(
      openingBalance,
    );

    final recoveryFailure =
        DriverSettlementUseCaseValidation.validateBalanceRecoveryMoney(
          resolvedInputs: resolvedInputs,
          snapshot: snapshot,
        );
    if (recoveryFailure != null) return FailureResult(recoveryFailure);

    final calculation = _calculator.calculateMoney(
      DriverSettlementUseCaseValidation.calculationMoneyInput(
        resolvedInputs: resolvedInputs,
        snapshot: snapshot,
      ),
    );
    final items = _resolvedItems(
      companyId: context.companyId,
      period: period,
      resolvedInputs: resolvedInputs,
      sourceItems: snapshot.sourceItems,
    );

    return Success(
      DriverSettlementResolvedCalculation(
        companyId: context.companyId,
        driverId: driverId,
        period: period,
        compensationRevisionId: compensation.id,
        currencyFractionDigits:
            resolvedInputs.currencyConfiguration.fractionDigits,
        calculation: calculation,
        items: items,
        notes: DriverSettlementUseCaseValidation.optional(params.notes),
      ),
    );
  }

  List<DriverSettlementMoneyItem> _resolvedItems({
    required String companyId,
    required DriverSettlementPeriod period,
    required DriverSettlementResolvedMoneyInputs resolvedInputs,
    required List<DriverSettlementMoneyItem> sourceItems,
  }) {
    if (!resolvedInputs.settlementDeductionsTotal.isPositive) {
      return List<DriverSettlementMoneyItem>.unmodifiable(sourceItems);
    }

    return List<DriverSettlementMoneyItem>.unmodifiable([
      ...sourceItems,
      DriverSettlementMoneyItem(
        companyId: companyId,
        sourceType: DriverSettlementItemSourceType.manualAdjustment,
        sourceDate: period.end,
        direction: DriverSettlementItemDirection.driverToCompany,
        amount: resolvedInputs.settlementDeductionsTotal,
        labelKey: _manualDeductionLabelKey,
        metadata: const {_manualAdjustmentKindKey: _settlementDeductionKind},
      ),
    ]);
  }
}
