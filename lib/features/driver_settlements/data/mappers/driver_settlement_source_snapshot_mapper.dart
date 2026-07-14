import '../../../../core/data/constants/db_common_fields.dart';
import '../../../../core/domain/services/driver_balance_calculator.dart';
import '../../domain/entities/driver_settlement_item.dart';
import '../../domain/entities/driver_settlement_item_direction.dart';
import '../../domain/entities/driver_settlement_item_source_type.dart';
import '../../domain/entities/driver_settlement_source_snapshot.dart';
import '../constants/driver_settlements_db_fields.dart';

const _movementTypeAdvance = 'advance';
const _movementTypeDriverCharge = 'driver_charge';
const _movementTypeCashReturn = 'cash_return';
const _paidByDriverAdvance = 'driver_advance';
const _paidByDriverCash = 'driver_cash';
const _labelAdvance = 'driver_settlement_item_advance';
const _labelDriverCharge = 'driver_settlement_item_driver_charge';
const _labelCashReturn = 'driver_settlement_item_cash_return';
const _labelTripExpense = 'driver_settlement_item_trip_expense';

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

  double calculateHistoricalOpeningBalance({
    double openingDriverBalance = 0,
    required List<Map<String, dynamic>> movementRows,
    required List<Map<String, dynamic>> tripExpenseRows,
  }) {
    final movementSummary = _mapMovements(
      companyId: '',
      rows: movementRows,
      includeItems: false,
    );
    final expenseSummary = _mapTripExpenses(
      companyId: '',
      rows: tripExpenseRows,
      includeItems: false,
    );

    return balanceCalculator.calculate(
      openingBalance: openingDriverBalance,
      advancesReceived: movementSummary.advancesTotal,
      driverCharges: movementSummary.driverChargesTotal,
      creditedTripExpenses: expenseSummary.total,
      cashReturned: movementSummary.returnedCashTotal,
    );
  }

  _MovementSummary _mapMovements({
    required String companyId,
    required List<Map<String, dynamic>> rows,
    bool includeItems = true,
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
        _movementTypeAdvance => const _MovementSemantics(
          labelKey: _labelAdvance,
          direction: DriverSettlementItemDirection.driverToCompany,
        ),
        _movementTypeDriverCharge => const _MovementSemantics(
          labelKey: _labelDriverCharge,
          direction: DriverSettlementItemDirection.driverToCompany,
        ),
        _movementTypeCashReturn => const _MovementSemantics(
          labelKey: _labelCashReturn,
          direction: DriverSettlementItemDirection.companyToDriver,
        ),
        _ => throw FormatException(
          'Unsupported driver financial movement type: $type',
        ),
      };

      switch (type) {
        case _movementTypeAdvance:
          advancesTotal += amount;
          break;
        case _movementTypeDriverCharge:
          driverChargesTotal += amount;
          break;
        case _movementTypeCashReturn:
          returnedCashTotal += amount;
          break;
      }

      if (!includeItems) continue;
      items.add(
        DriverSettlementItem(
          companyId: companyId,
          sourceType: DriverSettlementItemSourceType.driverFinancialMovement,
          sourceId: row[DbCommonFields.id] as String?,
          sourceDate: _dateFrom(row[DriverSettlementsDbFields.movementDate]),
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
    bool includeItems = true,
  }) {
    var total = 0.0;
    final items = <DriverSettlementItem>[];

    for (final row in rows) {
      final paidBy = row[DriverSettlementsDbFields.paidBy]?.toString();
      if (paidBy != _paidByDriverAdvance && paidBy != _paidByDriverCash) {
        throw FormatException(
          'Unsupported driver-paid trip expense source: $paidBy',
        );
      }

      final amount = _requiredPositiveAmount(
        row[DriverSettlementsDbFields.amount],
      );
      total += amount;

      if (!includeItems) continue;
      items.add(
        DriverSettlementItem(
          companyId: companyId,
          sourceType: DriverSettlementItemSourceType.tripExpense,
          sourceId: row[DbCommonFields.id] as String?,
          sourceDate: _dateFrom(row[DriverSettlementsDbFields.expenseDate]),
          direction: DriverSettlementItemDirection.companyToDriver,
          amount: amount,
          labelKey: _labelTripExpense,
          descriptionKey: row[DriverSettlementsDbFields.expenseName] as String?,
          metadata: {
            DriverSettlementsDbFields.paidBy: paidBy,
            DriverSettlementsDbFields.tripId:
                row[DriverSettlementsDbFields.tripId],
            DriverSettlementsDbFields.notes:
                row[DriverSettlementsDbFields.notes],
          },
        ),
      );
    }

    return _ExpenseSummary(
      total: balanceCalculator.roundMoney(total),
      items: items,
    );
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

  DateTime? _dateFrom(Object? value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
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
