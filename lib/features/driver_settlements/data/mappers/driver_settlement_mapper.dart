import '../../../../core/data/constants/db_common_fields.dart';
import '../../../../core/data/utils/db_timestamp.dart';
import '../../domain/entities/driver_settlement.dart';
import '../../domain/entities/driver_settlement_calculation_result.dart';
import '../../domain/entities/driver_settlement_item.dart';
import '../../domain/entities/driver_settlement_period.dart';
import '../../domain/entities/driver_settlement_status.dart';
import '../../domain/entities/driver_settlement_write_data.dart';
import '../constants/driver_settlements_db_fields.dart';
import '../models/driver_settlement_item_model.dart';
import '../models/driver_settlement_model.dart';

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
      DriverSettlementsDbFields.periodStart: _dateOnly(periodStart),
      DriverSettlementsDbFields.periodEnd: _dateOnly(periodEnd),
      DriverSettlementsDbFields.openingDriverBalance: openingDriverBalance,
      DriverSettlementsDbFields.advancesTotal: advancesTotal,
      DriverSettlementsDbFields.driverPaidTripExpensesTotal:
          driverPaidTripExpensesTotal,
      DriverSettlementsDbFields.returnedCashTotal: returnedCashTotal,
      DriverSettlementsDbFields.deductionsTotal: deductionsTotal,
      DriverSettlementsDbFields.settlementDeductionsTotal:
          settlementDeductionsTotal,
      DriverSettlementsDbFields.grossSalary: grossSalary,
      DriverSettlementsDbFields.salaryDeductionsTotal: salaryDeductionsTotal,
      DriverSettlementsDbFields.balanceDeductionApplied: balanceDeductionApplied,
      DriverSettlementsDbFields.netSalaryPayable: netSalaryPayable,
      DriverSettlementsDbFields.closingDriverBalance: closingDriverBalance,
      DriverSettlementsDbFields.status: status.value,
      DriverSettlementsDbFields.notes: notes,
      DriverSettlementsDbFields.finalizedAt:
          finalizedAt?.toUtc().toIso8601String(),
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

extension DriverSettlementDraftWriteDataMapper on DriverSettlementDraftWriteData {
  Map<String, dynamic> toInsertMap() {
    return {
      DbCommonFields.companyId: companyId,
      DriverSettlementsDbFields.driverId: driverId,
      DriverSettlementsDbFields.periodStart: _dateOnly(period.start),
      DriverSettlementsDbFields.periodEnd: _dateOnly(period.end),
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
      DriverSettlementsDbFields.netSalaryPayable:
          calculation.netSalaryPayable,
      DriverSettlementsDbFields.closingDriverBalance:
          calculation.closingDriverBalance,
      DriverSettlementsDbFields.status: DriverSettlementStatus.draft.value,
      DriverSettlementsDbFields.notes: notes,
    };
  }
}

extension DriverSettlementItemMapper on DriverSettlementItem {
  Map<String, dynamic> toInsertMap({
    required String settlementId,
  }) {
    return {
      DbCommonFields.companyId: companyId,
      DriverSettlementsDbFields.settlementId: settlementId,
      DriverSettlementsDbFields.sourceType: sourceType.value,
      DriverSettlementsDbFields.sourceId: sourceId,
      DriverSettlementsDbFields.sourceDate:
          sourceDate == null ? null : _dateOnly(sourceDate!),
      DriverSettlementsDbFields.direction: direction.value,
      DriverSettlementsDbFields.amount: amount,
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

String _dateOnly(DateTime value) {
  return '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}
