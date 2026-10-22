import '../../../../core/data/constants/db_common_fields.dart';
import '../../../../core/data/utils/db_date.dart';
import '../../../../core/data/utils/db_timestamp.dart';
import '../../../../core/domain/value_objects/business_date.dart';
import '../../../../core/domain/value_objects/currency_code.dart';
import '../../../../core/domain/value_objects/money.dart';
import '../../domain/entities/driver_balance_activity.dart';
import '../../domain/entities/driver_balance_activity_entry.dart';
import '../constants/driver_finance_db_fields.dart';
import 'driver_money_balance_mapper.dart';

/// Projects exactly the source rows selected for the canonical Money balance.
/// It does not choose settlement windows or recalculate financial totals.
final class DriverBalanceActivityMapper {
  final DriverMoneyBalanceSourceMapper _balanceMapper;

  const DriverBalanceActivityMapper({
    DriverMoneyBalanceSourceMapper balanceMapper =
        const DriverMoneyBalanceSourceMapper(),
  }) : _balanceMapper = balanceMapper;

  DriverBalanceActivity map({
    required String companyId,
    required String driverId,
    required String currencyCode,
    required int currencyFractionDigits,
    required Map<String, dynamic>? checkpointRow,
    required List<Map<String, dynamic>> movementRows,
    required List<Map<String, dynamic>> expenseLedgerRows,
  }) {
    final canonicalBalance = _balanceMapper
        .map(
          companyId: companyId,
          driverId: driverId,
          currencyCode: currencyCode,
          currencyFractionDigits: currencyFractionDigits,
          checkpointRow: checkpointRow,
          movementRows: movementRows,
          expenseLedgerRows: expenseLedgerRows,
        )
        .toEntity();

    final currency = canonicalBalance.currency;
    final entries = [
      for (final row in movementRows)
        _mapMovement(row, companyId, driverId, currency),
      for (final row in expenseLedgerRows)
        _mapExpense(row, companyId, driverId, currency),
    ];
    entries.sort(_compareEntries);

    return DriverBalanceActivity(
      canonicalBalance: canonicalBalance,
      entries: entries,
    );
  }

  DriverBalanceActivityEntry _mapMovement(
    Map<String, dynamic> row,
    String companyId,
    String driverId,
    CurrencyCode currency,
  ) {
    if (row[DbCommonFields.companyId] != companyId ||
        row[DriverFinanceDbFields.driverId] != driverId) {
      throw const FormatException('Driver movement attribution mismatch.');
    }

    final kind = switch (row[DriverFinanceDbFields.movementType]) {
      DriverFinanceDbValues.movementAdvance =>
        DriverBalanceActivityKind.advance,
      DriverFinanceDbValues.movementDriverCharge =>
        DriverBalanceActivityKind.driverCharge,
      DriverFinanceDbValues.movementCashReturn =>
        DriverBalanceActivityKind.cashReturn,
      _ => throw const FormatException('Unknown driver movement type.'),
    };
    return DriverBalanceActivityEntry(
      source: DriverBalanceActivitySource.financialMovement,
      sourceId: _requiredId(row),
      kind: kind,
      companyId: companyId,
      driverId: driverId,
      tripId: _optionalText(row[DriverFinanceDbFields.tripId]),
      businessDate: DbDate.decode(
        row[DriverFinanceDbFields.movementDate],
        field: DriverFinanceDbFields.movementDate,
      ),
      createdAt: _createdAt(row),
      amount: _money(row, currency),
      notes: _optionalText(row[DriverFinanceDbFields.notes]),
    );
  }

  DriverBalanceActivityEntry _mapExpense(
    Map<String, dynamic> row,
    String companyId,
    String driverId,
    CurrencyCode currency,
  ) {
    if (row[DbCommonFields.companyId] != companyId ||
        row[DriverFinanceDbFields.isVoided] != false ||
        (row[DriverFinanceDbFields.fundingSource] !=
                DriverFinanceDbValues.paidByDriverAdvance &&
            row[DriverFinanceDbFields.fundingSource] !=
                DriverFinanceDbValues.paidByDriverCash)) {
      throw const FormatException('Nonqualifying driver expense source.');
    }

    final tripId = _optionalText(row[DriverFinanceDbFields.tripId]);
    if (tripId == null) {
      throw const FormatException('Driver-funded expense has no trip.');
    }
    return DriverBalanceActivityEntry(
      source: DriverBalanceActivitySource.tripExpense,
      sourceId: _requiredId(row),
      kind: DriverBalanceActivityKind.driverPaidTripExpense,
      companyId: companyId,
      driverId: driverId,
      tripId: tripId,
      businessDate: DbDate.decode(
        row[DriverFinanceDbFields.expenseDate],
        field: DriverFinanceDbFields.expenseDate,
      ),
      createdAt: _createdAt(row),
      amount: _money(row, currency),
      description: _optionalText(row[DriverFinanceDbFields.description]),
      notes: _optionalText(row[DriverFinanceDbFields.notes]),
    );
  }

  Money _money(Map<String, dynamic> row, CurrencyCode currency) {
    final value = row[DriverFinanceDbFields.amountMinorUnits];
    final minorUnits = value is int ? value : int.tryParse(value?.toString() ?? '');
    if (minorUnits == null || minorUnits <= 0) {
      throw const FormatException('Invalid activity minor units.');
    }
    return Money(minorUnits: minorUnits, currency: currency);
  }

  String _requiredId(Map<String, dynamic> row) {
    final id = _optionalText(row[DbCommonFields.id]);
    if (id == null) throw const FormatException('Activity source id required.');
    return id;
  }

  DateTime _createdAt(Map<String, dynamic> row) => DbTimestamp.decode(
    row[DbCommonFields.createdAt],
    field: DbCommonFields.createdAt,
  );

  String? _optionalText(Object? value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  int _compareEntries(
    DriverBalanceActivityEntry left,
    DriverBalanceActivityEntry right,
  ) {
    final dateOrder = left.businessDate.compareTo(right.businessDate);
    if (dateOrder != 0) return dateOrder;
    final createdOrder = left.createdAt.compareTo(right.createdAt);
    if (createdOrder != 0) return createdOrder;
    return left.stableId.compareTo(right.stableId);
  }
}
