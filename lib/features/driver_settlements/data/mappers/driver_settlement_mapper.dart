import '../../../../core/data/constants/db_common_fields.dart';
import '../../../../core/data/utils/db_date.dart';
import '../../../../core/data/utils/db_timestamp.dart';
import '../../../../core/domain/services/money_decimal_codec.dart';
import '../../../../core/domain/value_objects/currency_configuration.dart';
import '../../domain/entities/driver_settlement.dart';
import '../../domain/entities/driver_settlement_calculation_result.dart';
import '../../domain/entities/driver_settlement_item.dart';
import '../../domain/entities/driver_settlement_money_item.dart';
import '../../domain/entities/driver_settlement_period.dart';
import '../../domain/entities/driver_settlement_status.dart';
import '../../domain/entities/driver_settlement_write_data.dart';
import '../constants/driver_settlements_db_fields.dart';
import '../models/driver_settlement_item_model.dart';
import '../models/driver_settlement_model.dart';

const _moneyCodec = MoneyDecimalCodec();

extension DriverSettlementModelMapper on DriverSettlementModel {
  DriverSettlement toEntity() {
    return DriverSettlement(
      id: id,
      companyId: companyId,
      driverId: driverId,
      period: DriverSettlementPeriod(start: periodStart, end: periodEnd),
      calculation: DriverSettlementCalculationResult(
        openingDriverBalance: openingDriverBalance,
        advancesTotal: advancesTotal,
        driverPaidTripExpensesTotal: driverPaidTripExpensesTotal,
        returnedCashTotal: returnedCashTotal,
        deductionsTotal: deductionsTotal,
        settlementDeductionsTotal: settlementDeductionsTotal,
        grossSalary: grossSalary,
        salaryDeductionsTotal: salaryDeductionsTotal,
        balanceDeductionApplied: balanceDeductionApplied,
        netSalaryPayable: netSalaryPayable,
        closingDriverBalance: closingDriverBalance,
      ),
      status: status,
      notes: notes,
      finalizedAt: finalizedAt,
      finalizedBy: finalizedBy,
      voidedAt: voidedAt,
      voidedBy: voidedBy,
      voidReason: voidReason,
      createdBy: createdBy,
      updatedBy: updatedBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
      items: items.map((item) => item.toEntity()).toList(),
    );
  }

  Map<String, Object?> toAuditValues() {
    return {
      DbCommonFields.id: id,
      DbCommonFields.companyId: companyId,
      DriverSettlementsDbFields.driverId: driverId,
      DriverSettlementsDbFields.periodStart: DbDate.encode(periodStart),
      DriverSettlementsDbFields.periodEnd: DbDate.encode(periodEnd),
      DriverSettlementsDbFields.compensationRevisionId: compensationRevisionId,
      DriverSettlementsDbFields.currencyCode: currencyCode,
      DriverSettlementsDbFields.currencyFractionDigits: currencyFractionDigits,
      DriverSettlementsDbFields.openingDriverBalance: openingDriverBalance,
      DriverSettlementsDbFields.openingDriverBalanceMinorUnits:
          openingDriverBalanceMinorUnits,
      DriverSettlementsDbFields.advancesTotal: advancesTotal,
      DriverSettlementsDbFields.advancesTotalMinorUnits: advancesTotalMinorUnits,
      DriverSettlementsDbFields.driverPaidTripExpensesTotal:
          driverPaidTripExpensesTotal,
      DriverSettlementsDbFields.driverPaidTripExpensesTotalMinorUnits:
          driverPaidTripExpensesTotalMinorUnits,
      DriverSettlementsDbFields.returnedCashTotal: returnedCashTotal,
      DriverSettlementsDbFields.returnedCashTotalMinorUnits:
          returnedCashTotalMinorUnits,
      DriverSettlementsDbFields.deductionsTotal: deductionsTotal,
      DriverSettlementsDbFields.deductionsTotalMinorUnits:
          deductionsTotalMinorUnits,
      DriverSettlementsDbFields.settlementDeductionsTotal:
          settlementDeductionsTotal,
      DriverSettlementsDbFields.settlementDeductionsTotalMinorUnits:
          settlementDeductionsTotalMinorUnits,
      DriverSettlementsDbFields.grossSalary: grossSalary,
      DriverSettlementsDbFields.grossSalaryMinorUnits: grossSalaryMinorUnits,
      DriverSettlementsDbFields.salaryDeductionsTotal: salaryDeductionsTotal,
      DriverSettlementsDbFields.salaryDeductionsTotalMinorUnits:
          salaryDeductionsTotalMinorUnits,
      DriverSettlementsDbFields.balanceDeductionApplied:
          balanceDeductionApplied,
      DriverSettlementsDbFields.balanceDeductionAppliedMinorUnits:
          balanceDeductionAppliedMinorUnits,
      DriverSettlementsDbFields.netSalaryPayable: netSalaryPayable,
      DriverSettlementsDbFields.netSalaryPayableMinorUnits:
          netSalaryPayableMinorUnits,
      DriverSettlementsDbFields.closingDriverBalance: closingDriverBalance,
      DriverSettlementsDbFields.closingDriverBalanceMinorUnits:
          closingDriverBalanceMinorUnits,
      DriverSettlementsDbFields.status: status.value,
      DriverSettlementsDbFields.notes: notes,
      DriverSettlementsDbFields.finalizedAt: finalizedAt
          ?.toUtc()
          .toIso8601String(),
      DriverSettlementsDbFields.finalizedBy: finalizedBy,
      DriverSettlementsDbFields.voidedAt: voidedAt?.toUtc().toIso8601String(),
      DriverSettlementsDbFields.voidedBy: voidedBy,
      DriverSettlementsDbFields.voidReason: voidReason,
      DriverSettlementsDbFields.createdBy: createdBy,
      DriverSettlementsDbFields.updatedBy: updatedBy,
      DbCommonFields.createdAt: createdAt?.toUtc().toIso8601String(),
      DbCommonFields.updatedAt: updatedAt?.toUtc().toIso8601String(),
      'items_count': items.length,
    };
  }
}

extension DriverSettlementItemModelMapper on DriverSettlementItemModel {
  DriverSettlementItem toEntity() {
    return DriverSettlementItem(
      id: id,
      companyId: companyId,
      settlementId: settlementId,
      sourceType: sourceType,
      sourceId: sourceId,
      sourceDate: sourceDate,
      direction: direction,
      amount: amount,
      labelKey: labelKey,
      descriptionKey: descriptionKey,
      metadata: metadata,
    );
  }
}

extension DriverSettlementDraftWriteDataMapper
    on DriverSettlementDraftWriteData {
  Map<String, dynamic> toInsertMap() {
    return {
      DbCommonFields.companyId: companyId,
      DriverSettlementsDbFields.driverId: driverId,
      DriverSettlementsDbFields.periodStart: DbDate.encode(period.start),
      DriverSettlementsDbFields.periodEnd: DbDate.encode(period.end),
      DriverSettlementsDbFields.openingDriverBalance:
          calculation.openingDriverBalance,
      DriverSettlementsDbFields.advancesTotal: calculation.advancesTotal,
      DriverSettlementsDbFields.driverPaidTripExpensesTotal:
          calculation.driverPaidTripExpensesTotal,
      DriverSettlementsDbFields.returnedCashTotal:
          calculation.returnedCashTotal,
      DriverSettlementsDbFields.deductionsTotal: calculation.deductionsTotal,
      DriverSettlementsDbFields.settlementDeductionsTotal:
          calculation.settlementDeductionsTotal,
      DriverSettlementsDbFields.grossSalary: calculation.grossSalary,
      DriverSettlementsDbFields.salaryDeductionsTotal:
          calculation.salaryDeductionsTotal,
      DriverSettlementsDbFields.balanceDeductionApplied:
          calculation.balanceDeductionApplied,
      DriverSettlementsDbFields.netSalaryPayable: calculation.netSalaryPayable,
      DriverSettlementsDbFields.closingDriverBalance:
          calculation.closingDriverBalance,
      DriverSettlementsDbFields.status: DriverSettlementStatus.draft.value,
      DriverSettlementsDbFields.notes: notes,
    };
  }
}

extension DriverSettlementMoneyDraftWriteDataMapper
    on DriverSettlementMoneyDraftWriteData {
  Map<String, dynamic> toMoneyInsertMap() {
    final configuration = CurrencyConfiguration(
      currency: calculation.grossSalary.currency,
      fractionDigits: currencyFractionDigits,
    );
    final value = calculation;
    return {
      DbCommonFields.companyId: companyId,
      DriverSettlementsDbFields.driverId: driverId,
      DriverSettlementsDbFields.periodStart: DbDate.encode(period.start),
      DriverSettlementsDbFields.periodEnd: DbDate.encode(period.end),
      DriverSettlementsDbFields.compensationRevisionId: compensationRevisionId,
      DriverSettlementsDbFields.currencyCode: configuration.currency.value,
      DriverSettlementsDbFields.currencyFractionDigits:
          configuration.fractionDigits,
      DriverSettlementsDbFields.openingDriverBalance: _moneyCodec.encode(
        value.openingDriverBalance,
        configuration: configuration,
      ),
      DriverSettlementsDbFields.openingDriverBalanceMinorUnits:
          value.openingDriverBalance.minorUnits,
      DriverSettlementsDbFields.advancesTotal: _moneyCodec.encodeNonNegative(
        value.advancesTotal,
        configuration: configuration,
      ),
      DriverSettlementsDbFields.advancesTotalMinorUnits:
          value.advancesTotal.minorUnits,
      DriverSettlementsDbFields.driverPaidTripExpensesTotal: _moneyCodec
          .encodeNonNegative(
            value.driverPaidTripExpensesTotal,
            configuration: configuration,
          ),
      DriverSettlementsDbFields.driverPaidTripExpensesTotalMinorUnits:
          value.driverPaidTripExpensesTotal.minorUnits,
      DriverSettlementsDbFields.returnedCashTotal: _moneyCodec.encodeNonNegative(
        value.returnedCashTotal,
        configuration: configuration,
      ),
      DriverSettlementsDbFields.returnedCashTotalMinorUnits:
          value.returnedCashTotal.minorUnits,
      DriverSettlementsDbFields.deductionsTotal: _moneyCodec.encodeNonNegative(
        value.deductionsTotal,
        configuration: configuration,
      ),
      DriverSettlementsDbFields.deductionsTotalMinorUnits:
          value.deductionsTotal.minorUnits,
      DriverSettlementsDbFields.settlementDeductionsTotal: _moneyCodec
          .encodeNonNegative(
            value.settlementDeductionsTotal,
            configuration: configuration,
          ),
      DriverSettlementsDbFields.settlementDeductionsTotalMinorUnits:
          value.settlementDeductionsTotal.minorUnits,
      DriverSettlementsDbFields.grossSalary: _moneyCodec.encodeNonNegative(
        value.grossSalary,
        configuration: configuration,
      ),
      DriverSettlementsDbFields.grossSalaryMinorUnits:
          value.grossSalary.minorUnits,
      DriverSettlementsDbFields.salaryDeductionsTotal: _moneyCodec
          .encodeNonNegative(
            value.salaryDeductionsTotal,
            configuration: configuration,
          ),
      DriverSettlementsDbFields.salaryDeductionsTotalMinorUnits:
          value.salaryDeductionsTotal.minorUnits,
      DriverSettlementsDbFields.balanceDeductionApplied: _moneyCodec
          .encodeNonNegative(
            value.balanceDeductionApplied,
            configuration: configuration,
          ),
      DriverSettlementsDbFields.balanceDeductionAppliedMinorUnits:
          value.balanceDeductionApplied.minorUnits,
      DriverSettlementsDbFields.netSalaryPayable: _moneyCodec.encodeNonNegative(
        value.netSalaryPayable,
        configuration: configuration,
      ),
      DriverSettlementsDbFields.netSalaryPayableMinorUnits:
          value.netSalaryPayable.minorUnits,
      DriverSettlementsDbFields.closingDriverBalance: _moneyCodec.encode(
        value.closingDriverBalance,
        configuration: configuration,
      ),
      DriverSettlementsDbFields.closingDriverBalanceMinorUnits:
          value.closingDriverBalance.minorUnits,
      DriverSettlementsDbFields.status: DriverSettlementStatus.draft.value,
      DriverSettlementsDbFields.notes: notes,
    };
  }
}

extension DriverSettlementItemMapper on DriverSettlementItem {
  Map<String, dynamic> toInsertMap({required String settlementId}) {
    return {
      DbCommonFields.companyId: companyId,
      DriverSettlementsDbFields.settlementId: settlementId,
      DriverSettlementsDbFields.sourceType: sourceType.value,
      DriverSettlementsDbFields.sourceId: sourceId,
      DriverSettlementsDbFields.sourceDate: DbDate.encodeNullable(sourceDate),
      DriverSettlementsDbFields.direction: direction.value,
      DriverSettlementsDbFields.amount: amount,
      DriverSettlementsDbFields.labelKey: labelKey,
      DriverSettlementsDbFields.descriptionKey: descriptionKey,
      DriverSettlementsDbFields.metadata: metadata,
    };
  }
}

extension DriverSettlementMoneyItemMapper on DriverSettlementMoneyItem {
  Map<String, dynamic> toMoneyInsertMap({
    required String settlementId,
    required int currencyFractionDigits,
  }) {
    final configuration = CurrencyConfiguration(
      currency: amount.currency,
      fractionDigits: currencyFractionDigits,
    );
    return {
      DbCommonFields.companyId: companyId,
      DriverSettlementsDbFields.settlementId: settlementId,
      DriverSettlementsDbFields.sourceType: sourceType.value,
      DriverSettlementsDbFields.sourceId: sourceId,
      DriverSettlementsDbFields.sourceDate: DbDate.encodeNullable(sourceDate),
      DriverSettlementsDbFields.direction: direction.value,
      DriverSettlementsDbFields.amount: _moneyCodec.encodeNonNegative(
        amount,
        configuration: configuration,
      ),
      DriverSettlementsDbFields.amountMinorUnits: amount.minorUnits,
      DriverSettlementsDbFields.currencyCode: amount.currency.value,
      DriverSettlementsDbFields.currencyFractionDigits: currencyFractionDigits,
      DriverSettlementsDbFields.labelKey: labelKey,
      DriverSettlementsDbFields.descriptionKey: descriptionKey,
      DriverSettlementsDbFields.metadata: metadata,
    };
  }
}

extension DriverSettlementFinalizeDataMapper on DriverSettlementFinalizeData {
  Map<String, dynamic> toUpdateMap({required String? actorUserId}) {
    return {
      DriverSettlementsDbFields.status: DriverSettlementStatus.finalized.value,
      DriverSettlementsDbFields.finalizedAt: DbTimestamp.nowUtcIsoString(),
      DriverSettlementsDbFields.finalizedBy: actorUserId,
      DriverSettlementsDbFields.updatedBy: actorUserId,
      DbCommonFields.updatedAt: DbTimestamp.nowUtcIsoString(),
    };
  }
}

extension DriverSettlementVoidDataMapper on DriverSettlementVoidData {
  Map<String, dynamic> toUpdateMap({required String? actorUserId}) {
    return {
      DriverSettlementsDbFields.status: DriverSettlementStatus.voided.value,
      DriverSettlementsDbFields.voidedAt: DbTimestamp.nowUtcIsoString(),
      DriverSettlementsDbFields.voidedBy: actorUserId,
      DriverSettlementsDbFields.voidReason: reason,
      DriverSettlementsDbFields.updatedBy: actorUserId,
      DbCommonFields.updatedAt: DbTimestamp.nowUtcIsoString(),
    };
  }
}
