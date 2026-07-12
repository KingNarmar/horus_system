import '../../domain/entities/driver_settlement_status.dart';
import '../constants/driver_settlements_db_fields.dart';
import 'driver_settlement_item_model.dart';

class DriverSettlementModel {
  final String id;
  final String companyId;
  final String driverId;
  final DateTime periodStart;
  final DateTime periodEnd;
  final double openingDriverBalance;
  final double advancesTotal;
  final double driverPaidTripExpensesTotal;
  final double returnedCashTotal;
  final double deductionsTotal;
  final double settlementDeductionsTotal;
  final double grossSalary;
  final double salaryDeductionsTotal;
  final double balanceDeductionApplied;
  final double netSalaryPayable;
  final double closingDriverBalance;
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
      periodStart: _requiredDate(map[DriverSettlementsDbFields.periodStart]),
      periodEnd: _requiredDate(map[DriverSettlementsDbFields.periodEnd]),
      openingDriverBalance: _amountFrom(
        map[DriverSettlementsDbFields.openingDriverBalance],
      ),
      advancesTotal: _amountFrom(map[DriverSettlementsDbFields.advancesTotal]),
      driverPaidTripExpensesTotal: _amountFrom(
        map[DriverSettlementsDbFields.driverPaidTripExpensesTotal],
      ),
      returnedCashTotal: _amountFrom(
        map[DriverSettlementsDbFields.returnedCashTotal],
      ),
      deductionsTotal: _amountFrom(
        map[DriverSettlementsDbFields.deductionsTotal],
      ),
      settlementDeductionsTotal: _amountFrom(
        map[DriverSettlementsDbFields.settlementDeductionsTotal],
      ),
      grossSalary: _amountFrom(map[DriverSettlementsDbFields.grossSalary]),
      salaryDeductionsTotal: _amountFrom(
        map[DriverSettlementsDbFields.salaryDeductionsTotal],
      ),
      balanceDeductionApplied: _amountFrom(
        map[DriverSettlementsDbFields.balanceDeductionApplied],
      ),
      netSalaryPayable: _amountFrom(
        map[DriverSettlementsDbFields.netSalaryPayable],
      ),
      closingDriverBalance: _amountFrom(
        map[DriverSettlementsDbFields.closingDriverBalance],
      ),
      status: DriverSettlementStatus.fromValue(
        map[DriverSettlementsDbFields.status].toString(),
      ),
      notes: map[DriverSettlementsDbFields.notes] as String?,
      finalizedAt: _dateTimeFrom(map[DriverSettlementsDbFields.finalizedAt]),
      finalizedBy: map[DriverSettlementsDbFields.finalizedBy] as String?,
      voidedAt: _dateTimeFrom(map[DriverSettlementsDbFields.voidedAt]),
      voidedBy: map[DriverSettlementsDbFields.voidedBy] as String?,
      voidReason: map[DriverSettlementsDbFields.voidReason] as String?,
      createdBy: map[DriverSettlementsDbFields.createdBy] as String?,
      updatedBy: map[DriverSettlementsDbFields.updatedBy] as String?,
      createdAt: _dateTimeFrom(map['created_at']),
      updatedAt: _dateTimeFrom(map['updated_at']),
      items: items,
    );
  }
}

double _amountFrom(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

DateTime _requiredDate(Object? value) {
  return DateTime.tryParse(value.toString()) ?? DateTime.fromMillisecondsSinceEpoch(0);
}

DateTime? _dateTimeFrom(Object? value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}
