import '../../../../core/data/utils/db_date.dart';
import '../../../../core/data/utils/db_timestamp.dart';
import '../../../../core/domain/value_objects/business_date.dart';
import '../../domain/entities/driver_settlement_status.dart';
import '../constants/driver_settlements_db_fields.dart';
import 'driver_settlement_item_model.dart';

class DriverSettlementModel {
  final String id;
  final String companyId;
  final String driverId;
  final BusinessDate periodStart;
  final BusinessDate periodEnd;
  final String? compensationRevisionId;
  final String? currencyCode;
  final int? currencyFractionDigits;
  final double openingDriverBalance;
  final int? openingDriverBalanceMinorUnits;
  final double advancesTotal;
  final int? advancesTotalMinorUnits;
  final double driverPaidTripExpensesTotal;
  final int? driverPaidTripExpensesTotalMinorUnits;
  final double returnedCashTotal;
  final int? returnedCashTotalMinorUnits;
  final double deductionsTotal;
  final int? deductionsTotalMinorUnits;
  final double settlementDeductionsTotal;
  final int? settlementDeductionsTotalMinorUnits;
  final double grossSalary;
  final int? grossSalaryMinorUnits;
  final double salaryDeductionsTotal;
  final int? salaryDeductionsTotalMinorUnits;
  final double balanceDeductionApplied;
  final int? balanceDeductionAppliedMinorUnits;
  final double netSalaryPayable;
  final int? netSalaryPayableMinorUnits;
  final double closingDriverBalance;
  final int? closingDriverBalanceMinorUnits;
  final DriverSettlementStatus status;
  final String? notes;
  final DateTime? finalizedAt;
  final String? finalizedBy;
  final DateTime? voidedAt;
  final String? voidedBy;
  final String? voidReason;
  final String? createdBy;
  final String? updatedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<DriverSettlementItemModel> items;

  const DriverSettlementModel({
    required this.id,
    required this.companyId,
    required this.driverId,
    required this.periodStart,
    required this.periodEnd,
    required this.openingDriverBalance,
    required this.advancesTotal,
    required this.driverPaidTripExpensesTotal,
    required this.returnedCashTotal,
    required this.deductionsTotal,
    required this.settlementDeductionsTotal,
    required this.grossSalary,
    required this.salaryDeductionsTotal,
    required this.balanceDeductionApplied,
    required this.netSalaryPayable,
    required this.closingDriverBalance,
    required this.status,
    this.compensationRevisionId,
    this.currencyCode,
    this.currencyFractionDigits,
    this.openingDriverBalanceMinorUnits,
    this.advancesTotalMinorUnits,
    this.driverPaidTripExpensesTotalMinorUnits,
    this.returnedCashTotalMinorUnits,
    this.deductionsTotalMinorUnits,
    this.settlementDeductionsTotalMinorUnits,
    this.grossSalaryMinorUnits,
    this.salaryDeductionsTotalMinorUnits,
    this.balanceDeductionAppliedMinorUnits,
    this.netSalaryPayableMinorUnits,
    this.closingDriverBalanceMinorUnits,
    this.notes,
    this.finalizedAt,
    this.finalizedBy,
    this.voidedAt,
    this.voidedBy,
    this.voidReason,
    this.createdBy,
    this.updatedBy,
    this.createdAt,
    this.updatedAt,
    this.items = const [],
  });

  factory DriverSettlementModel.fromMap(
    Map<String, dynamic> map, {
    List<DriverSettlementItemModel> items = const [],
  }) {
    return DriverSettlementModel(
      id: map['id'] as String,
      companyId: map['company_id'] as String,
      driverId: map[DriverSettlementsDbFields.driverId] as String,
      periodStart: DbDate.decode(
        map[DriverSettlementsDbFields.periodStart],
        field: DriverSettlementsDbFields.periodStart,
      ),
      periodEnd: DbDate.decode(
        map[DriverSettlementsDbFields.periodEnd],
        field: DriverSettlementsDbFields.periodEnd,
      ),
      compensationRevisionId:
          map[DriverSettlementsDbFields.compensationRevisionId] as String?,
      currencyCode: map[DriverSettlementsDbFields.currencyCode] as String?,
      currencyFractionDigits: _intFromNullable(
        map[DriverSettlementsDbFields.currencyFractionDigits],
      ),
      openingDriverBalance: _amountFrom(
        map[DriverSettlementsDbFields.openingDriverBalance],
      ),
      openingDriverBalanceMinorUnits: _intFromNullable(
        map[DriverSettlementsDbFields.openingDriverBalanceMinorUnits],
      ),
      advancesTotal: _amountFrom(map[DriverSettlementsDbFields.advancesTotal]),
      advancesTotalMinorUnits: _intFromNullable(
        map[DriverSettlementsDbFields.advancesTotalMinorUnits],
      ),
      driverPaidTripExpensesTotal: _amountFrom(
        map[DriverSettlementsDbFields.driverPaidTripExpensesTotal],
      ),
      driverPaidTripExpensesTotalMinorUnits: _intFromNullable(
        map[DriverSettlementsDbFields.driverPaidTripExpensesTotalMinorUnits],
      ),
      returnedCashTotal: _amountFrom(
        map[DriverSettlementsDbFields.returnedCashTotal],
      ),
      returnedCashTotalMinorUnits: _intFromNullable(
        map[DriverSettlementsDbFields.returnedCashTotalMinorUnits],
      ),
      deductionsTotal: _amountFrom(
        map[DriverSettlementsDbFields.deductionsTotal],
      ),
      deductionsTotalMinorUnits: _intFromNullable(
        map[DriverSettlementsDbFields.deductionsTotalMinorUnits],
      ),
      settlementDeductionsTotal: _amountFrom(
        map[DriverSettlementsDbFields.settlementDeductionsTotal],
      ),
      settlementDeductionsTotalMinorUnits: _intFromNullable(
        map[DriverSettlementsDbFields.settlementDeductionsTotalMinorUnits],
      ),
      grossSalary: _amountFrom(map[DriverSettlementsDbFields.grossSalary]),
      grossSalaryMinorUnits: _intFromNullable(
        map[DriverSettlementsDbFields.grossSalaryMinorUnits],
      ),
      salaryDeductionsTotal: _amountFrom(
        map[DriverSettlementsDbFields.salaryDeductionsTotal],
      ),
      salaryDeductionsTotalMinorUnits: _intFromNullable(
        map[DriverSettlementsDbFields.salaryDeductionsTotalMinorUnits],
      ),
      balanceDeductionApplied: _amountFrom(
        map[DriverSettlementsDbFields.balanceDeductionApplied],
      ),
      balanceDeductionAppliedMinorUnits: _intFromNullable(
        map[DriverSettlementsDbFields.balanceDeductionAppliedMinorUnits],
      ),
      netSalaryPayable: _amountFrom(
        map[DriverSettlementsDbFields.netSalaryPayable],
      ),
      netSalaryPayableMinorUnits: _intFromNullable(
        map[DriverSettlementsDbFields.netSalaryPayableMinorUnits],
      ),
      closingDriverBalance: _amountFrom(
        map[DriverSettlementsDbFields.closingDriverBalance],
      ),
      closingDriverBalanceMinorUnits: _intFromNullable(
        map[DriverSettlementsDbFields.closingDriverBalanceMinorUnits],
      ),
      status: DriverSettlementStatus.fromValue(
        map[DriverSettlementsDbFields.status].toString(),
      ),
      notes: map[DriverSettlementsDbFields.notes] as String?,
      finalizedAt: DbTimestamp.decodeNullable(
        map[DriverSettlementsDbFields.finalizedAt],
        field: DriverSettlementsDbFields.finalizedAt,
      ),
      finalizedBy: map[DriverSettlementsDbFields.finalizedBy] as String?,
      voidedAt: DbTimestamp.decodeNullable(
        map[DriverSettlementsDbFields.voidedAt],
        field: DriverSettlementsDbFields.voidedAt,
      ),
      voidedBy: map[DriverSettlementsDbFields.voidedBy] as String?,
      voidReason: map[DriverSettlementsDbFields.voidReason] as String?,
      createdBy: map[DriverSettlementsDbFields.createdBy] as String?,
      updatedBy: map[DriverSettlementsDbFields.updatedBy] as String?,
      createdAt: DbTimestamp.decodeNullable(
        map['created_at'],
        field: 'created_at',
      ),
      updatedAt: DbTimestamp.decodeNullable(
        map['updated_at'],
        field: 'updated_at',
      ),
      items: items,
    );
  }
}

double _amountFrom(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

int? _intFromNullable(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}
