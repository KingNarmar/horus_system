import '../../../../core/data/constants/db_common_fields.dart';
import '../../../../core/data/utils/db_date.dart';
import '../../../../core/domain/value_objects/currency_configuration.dart';
import '../../../../core/domain/value_objects/money.dart';
import '../../domain/entities/driver_settlement_item_direction.dart';
import '../../domain/entities/driver_settlement_item_source_type.dart';
import '../../domain/entities/driver_settlement_money_item.dart';
import '../../domain/entities/driver_settlement_money_source_snapshot.dart';
import '../constants/driver_settlement_source_values.dart';
import '../constants/driver_settlements_db_fields.dart';

final class DriverSettlementMoneySourceSnapshotMapper {
  const DriverSettlementMoneySourceSnapshotMapper();

  DriverSettlementMoneySourceSnapshot map({
    required String companyId,
    required CurrencyConfiguration currencyConfiguration,
    required List<Map<String, dynamic>> movementRows,
    required List<Map<String, dynamic>> tripExpenseRows,
  }) {
    final movementSummary = _mapMovements(
      companyId: companyId,
      currencyConfiguration: currencyConfiguration,
      rows: movementRows,
    );
    final expenseSummary = _mapTripExpenses(
      companyId: companyId,
      currencyConfiguration: currencyConfiguration,
      rows: tripExpenseRows,
    );
    final zero = Money(
      minorUnits: 0,
      currency: currencyConfiguration.currency,
    );

    return DriverSettlementMoneySourceSnapshot(
      openingDriverBalance: zero,
      advancesTotal: movementSummary.advancesTotal,
      driverPaidTripExpensesTotal: expenseSummary.total,
      returnedCashTotal: movementSummary.returnedCashTotal,
      deductionsTotal: movementSummary.driverChargesTotal,
      sourceItems: [...movementSummary.items, ...expenseSummary.items],
    );
  }

  _MoneyMovementSummary _mapMovements({
    required String companyId,
    required CurrencyConfiguration currencyConfiguration,
    required List<Map<String, dynamic>> rows,
  }) {
    var advancesMinorUnits = 0;
    var driverChargesMinorUnits = 0;
    var returnedCashMinorUnits = 0;
    final items = <DriverSettlementMoneyItem>[];

    for (final row in rows) {
      final type = row[DriverSettlementsDbFields.movementType]?.toString();
      final amount = _requiredPositiveMoney(row, currencyConfiguration);
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
          advancesMinorUnits += amount.minorUnits;
          break;
        case DriverSettlementSourceValues.movementDriverCharge:
          driverChargesMinorUnits += amount.minorUnits;
          break;
        case DriverSettlementSourceValues.movementCashReturn:
          returnedCashMinorUnits += amount.minorUnits;
          break;
      }

      items.add(
        DriverSettlementMoneyItem(
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

    final currency = currencyConfiguration.currency;
    return _MoneyMovementSummary(
      advancesTotal: Money(minorUnits: advancesMinorUnits, currency: currency),
      driverChargesTotal: Money(
        minorUnits: driverChargesMinorUnits,
        currency: currency,
      ),
      returnedCashTotal: Money(
        minorUnits: returnedCashMinorUnits,
        currency: currency,
      ),
      items: items,
    );
  }

  _MoneyExpenseSummary _mapTripExpenses({
    required String companyId,
    required CurrencyConfiguration currencyConfiguration,
    required List<Map<String, dynamic>> rows,
  }) {
    var totalMinorUnits = 0;
    final items = <DriverSettlementMoneyItem>[];

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

      final amount = _requiredPositiveMoney(row, currencyConfiguration);
      totalMinorUnits += amount.minorUnits;
      items.add(
        DriverSettlementMoneyItem(
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

    return _MoneyExpenseSummary(
      total: Money(
        minorUnits: totalMinorUnits,
        currency: currencyConfiguration.currency,
      ),
      items: items,
    );
  }

  Money _requiredPositiveMoney(
    Map<String, dynamic> row,
    CurrencyConfiguration currencyConfiguration,
  ) {
    final currencyCode = row[DriverSettlementsDbFields.currencyCode]
        ?.toString();
    final fractionDigits = _requiredInt(
      row[DriverSettlementsDbFields.currencyFractionDigits],
    );
    if (currencyCode != currencyConfiguration.currency.value ||
        fractionDigits != currencyConfiguration.fractionDigits) {
      throw FormatException(
        'Settlement source currency does not match company currency.',
      );
    }

    final minorUnits = _requiredInt(
      row[DriverSettlementsDbFields.amountMinorUnits],
    );
    if (minorUnits <= 0) {
      throw FormatException('Invalid positive money minor units: $minorUnits');
    }
    return Money(
      minorUnits: minorUnits,
      currency: currencyConfiguration.currency,
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

  int _requiredInt(Object? value) {
    if (value is int) return value;
    if (value is num && value == value.toInt()) return value.toInt();
    final parsed = int.tryParse(value?.toString() ?? '');
    if (parsed == null) throw FormatException('Invalid integer value: $value');
    return parsed;
  }
}

final class _MovementSemantics {
  final String labelKey;
  final DriverSettlementItemDirection direction;

  const _MovementSemantics({required this.labelKey, required this.direction});
}

final class _MoneyMovementSummary {
  final Money advancesTotal;
  final Money driverChargesTotal;
  final Money returnedCashTotal;
  final List<DriverSettlementMoneyItem> items;

  const _MoneyMovementSummary({
    required this.advancesTotal,
    required this.driverChargesTotal,
    required this.returnedCashTotal,
    required this.items,
  });
}

final class _MoneyExpenseSummary {
  final Money total;
  final List<DriverSettlementMoneyItem> items;

  const _MoneyExpenseSummary({required this.total, required this.items});
}
