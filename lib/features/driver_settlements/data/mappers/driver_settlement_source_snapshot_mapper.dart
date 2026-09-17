import '../../../../core/data/constants/db_common_fields.dart';
import '../../../../core/data/utils/db_date.dart';
import '../../../../core/domain/services/driver_balance_calculator.dart';
import '../../domain/entities/driver_settlement_item.dart';
import '../../domain/entities/driver_settlement_item_direction.dart';
import '../../domain/entities/driver_settlement_item_source_type.dart';
import '../../domain/entities/driver_settlement_source_snapshot.dart';
import '../constants/driver_settlement_source_values.dart';
import '../constants/driver_settlements_db_fields.dart';

class DriverSettlementSourceSnapshotMapper {
  final DriverBalanceCalculator balanceCalculator;

  const DriverSettlementSourceSnapshotMapper({
    this.balanceCalculator = const DriverBalanceCalculator(),
  });

  DriverSettlementSourceSnapshot map({
    required String companyId,
    required double openingDriverBalance,
    required List<Map<String, dynamic>> movementRows,
    required List<Map<String, dynamic>> tripExpenseRows,
  }) {
    final movementSummary = _mapMovements(
      companyId: companyId,
      rows: movementRows,
    );
    final expenseSummary = _mapTripExpenses(
      companyId: companyId,
      rows: tripExpenseRows,
    );

    return DriverSettlementSourceSnapshot(
      openingDriverBalance: balanceCalculator.roundMoney(openingDriverBalance),
      advancesTotal: movementSummary.advancesTotal,
      driverPaidTripExpensesTotal: expenseSummary.total,
      returnedCashTotal: movementSummary.returnedCashTotal,
      deductionsTotal: movementSummary.driverChargesTotal,
      sourceItems: [...movementSummary.items, ...expenseSummary.items],
    );
  }

  _MovementSummary _mapMovements({
    required String companyId,
    required List<Map<String, dynamic>> rows,
  }) {
    var advancesTotal = 0.0;
    var driverChargesTotal = 0.0;
    var returnedCashTotal = 0.0;
    final items = <DriverSettlementItem>[];

    for (final row in rows) {
      final type = row[DriverSettlementsDbFields.movementType]?.toString();
      final amount = _requiredPositiveAmount(
        row[DriverSettlementsDbFields.amount],
      );

      final semantics = switch (type) {
        DriverSettlementSourceValues.movementAdvance =>
          const _MovementSemantics(
            labelKey: DriverSettlementSourceValues.labelAdvance,
            direction: DriverSettlementItemDirection.driverToCompany,
          ),
        DriverSettlementSourceValues.movementDriverCharge =>
          const _MovementSemantics(
            labelKey: DriverSettlementSourceValues.labelDriverCharge,
            direction: DriverSettlementItemDirection.driverToCompany,
          ),
        DriverSettlementSourceValues.movementCashReturn =>
          const _MovementSemantics(
            labelKey: DriverSettlementSourceValues.labelCashReturn,
            direction: DriverSettlementItemDirection.companyToDriver,
          ),
        _ => throw FormatException(
          'Unsupported driver financial movement type: $type',
        ),
      };

      switch (type) {
        case DriverSettlementSourceValues.movementAdvance:
          advancesTotal += amount;
          break;
        case DriverSettlementSourceValues.movementDriverCharge:
          driverChargesTotal += amount;
          break;
        case DriverSettlementSourceValues.movementCashReturn:
          returnedCashTotal += amount;
          break;
      }

      items.add(
        DriverSettlementItem(
          companyId: companyId,
          sourceType: DriverSettlementItemSourceType.driverFinancialMovement,
          sourceId: row[DbCommonFields.id] as String?,
          sourceDate: DbDate.decodeNullable(
            row[DriverSettlementsDbFields.movementDate],
            field: DriverSettlementsDbFields.movementDate,
          ),
          direction: semantics.direction,
          amount: amount,
          labelKey: semantics.labelKey,
          descriptionKey: row[DriverSettlementsDbFields.notes] as String?,
          metadata: {
            DriverSettlementsDbFields.movementType: type,
            DriverSettlementsDbFields.tripId:
                row[DriverSettlementsDbFields.tripId],
          },
        ),
      );
    }

    return _MovementSummary(
      advancesTotal: balanceCalculator.roundMoney(advancesTotal),
      driverChargesTotal: balanceCalculator.roundMoney(driverChargesTotal),
      returnedCashTotal: balanceCalculator.roundMoney(returnedCashTotal),
      items: items,
    );
  }

  _ExpenseSummary _mapTripExpenses({
    required String companyId,
    required List<Map<String, dynamic>> rows,
  }) {
    var total = 0.0;
    final items = <DriverSettlementItem>[];

    for (final row in rows) {
      final fundingSource = row[DriverSettlementsDbFields.fundingSource]
          ?.toString();
      if (fundingSource !=
              DriverSettlementSourceValues.fundingSourceDriverAdvance &&
          fundingSource != DriverSettlementSourceValues.fundingSourceDriverCash) {
        throw FormatException(
          'Unsupported driver-paid trip expense source: $fundingSource',
        );
      }

      final amount = _minorUnitsToAmount(row);
      if (amount <= 0) {
        throw FormatException('Invalid positive money amount: $amount');
      }
      total += amount;

      items.add(
        DriverSettlementItem(
          companyId: companyId,
          sourceType: DriverSettlementItemSourceType.tripExpense,
          sourceId: _expenseSourceId(row),
          sourceDate: DbDate.decodeNullable(
            row[DriverSettlementsDbFields.expenseDate],
            field: DriverSettlementsDbFields.expenseDate,
          ),
          direction: DriverSettlementItemDirection.companyToDriver,
          amount: amount,
          labelKey: DriverSettlementSourceValues.labelTripExpense,
          descriptionKey: row[DriverSettlementsDbFields.description] as String?,
          metadata: {
            DriverSettlementsDbFields.paidBy: fundingSource,
            DriverSettlementsDbFields.tripId:
                row[DriverSettlementsDbFields.tripId],
          },
        ),
      );
    }

    return _ExpenseSummary(
      total: balanceCalculator.roundMoney(total),
      items: items,
    );
  }

  String? _expenseSourceId(Map<String, dynamic> row) {
    final originKind = row[DriverSettlementsDbFields.originKind]?.toString();
    final originId = row[DriverSettlementsDbFields.originId] as String?;
    if (originKind == DriverSettlementSourceValues.legacyTripExpenseOrigin &&
        originId != null) {
      return originId;
    }
    return row[DbCommonFields.id] as String?;
  }

  double _minorUnitsToAmount(Map<String, dynamic> row) {
    final minorUnits = _requiredInt(
      row[DriverSettlementsDbFields.amountMinorUnits],
    );
    final fractionDigits = _requiredInt(
      row[DriverSettlementsDbFields.currencyFractionDigits],
    );
    final factor = switch (fractionDigits) {
      0 => 1,
      1 => 10,
      2 => 100,
      3 => 1000,
      4 => 10000,
      _ => throw FormatException(
        'Unsupported currency fraction digits: $fractionDigits',
      ),
    };
    return minorUnits / factor;
  }

  int _requiredInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    final parsed = int.tryParse(value?.toString() ?? '');
    if (parsed == null) throw FormatException('Invalid integer value: $value');
    return parsed;
  }

  double _requiredPositiveAmount(Object? value) {
    final amount = switch (value) {
      num number => number.toDouble(),
      _ => double.tryParse(value?.toString() ?? ''),
    };
    if (amount == null || amount <= 0) {
      throw FormatException('Invalid positive money amount: $value');
    }
    return amount;
  }
}

class _MovementSemantics {
  final String labelKey;
  final DriverSettlementItemDirection direction;

  const _MovementSemantics({required this.labelKey, required this.direction});
}

class _MovementSummary {
  final double advancesTotal;
  final double driverChargesTotal;
  final double returnedCashTotal;
  final List<DriverSettlementItem> items;

  const _MovementSummary({
    required this.advancesTotal,
    required this.driverChargesTotal,
    required this.returnedCashTotal,
    required this.items,
  });
}

class _ExpenseSummary {
  final double total;
  final List<DriverSettlementItem> items;

  const _ExpenseSummary({required this.total, required this.items});
}
