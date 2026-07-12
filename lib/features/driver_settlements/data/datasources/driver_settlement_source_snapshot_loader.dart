import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/data/constants/db_common_fields.dart';
import '../../domain/entities/driver_settlement_item.dart';
import '../../domain/entities/driver_settlement_item_direction.dart';
import '../../domain/entities/driver_settlement_item_source_type.dart';
import '../../domain/entities/driver_settlement_period.dart';
import '../../domain/entities/driver_settlement_source_snapshot.dart';
import '../constants/driver_settlements_db_fields.dart';

const _driverFinancialMovementColumns = '''
id,
company_id,
driver_id,
trip_id,
movement_type,
amount,
movement_date,
notes
''';

const _tripExpenseColumns = '''
id,
company_id,
trip_id,
expense_name,
amount,
paid_by,
expense_date,
notes
''';

const _movementTypeAdvance = 'advance';
const _movementTypeDeduction = 'deduction';
const _paidByDriverAdvance = 'driver_advance';
const _paidByDriverCash = 'driver_cash';
const _labelAdvance = 'driver_settlement_item_advance';
const _labelDeduction = 'driver_settlement_item_deduction';
const _labelTripExpense = 'driver_settlement_item_trip_expense';

class DriverSettlementSourceSnapshotLoader {
  final SupabaseClient client;

  const DriverSettlementSourceSnapshotLoader(this.client);

  Future<DriverSettlementSourceSnapshot> load({
    required String companyId,
    required String driverId,
    required DriverSettlementPeriod period,
  }) async {
    final openingDriverBalance = await _getOpeningDriverBalance(
      companyId: companyId,
      driverId: driverId,
      period: period,
    );

    final movementRows = await _getDriverFinancialMovementRows(
      companyId: companyId,
      driverId: driverId,
      startInclusive: period.start,
      endInclusive: period.end,
    );
    final tripExpenseRows = await _getDriverPaidTripExpenseRows(
      companyId: companyId,
      driverId: driverId,
      startInclusive: period.start,
      endInclusive: period.end,
    );

    var advancesTotal = 0.0;
    var deductionsTotal = 0.0;
    final sourceItems = <DriverSettlementItem>[];

    for (final row in movementRows) {
      final type = row[DriverSettlementsDbFields.movementType]?.toString();
      final amount = _amountFrom(row[DriverSettlementsDbFields.amount]);
      final isAdvance = type == _movementTypeAdvance;
      if (isAdvance) {
        advancesTotal += amount;
      } else if (type == _movementTypeDeduction) {
        deductionsTotal += amount;
      }

      sourceItems.add(
        DriverSettlementItem(
          companyId: companyId,
          sourceType: DriverSettlementItemSourceType.driverFinancialMovement,
          sourceId: row[DbCommonFields.id] as String?,
          sourceDate: _dateFrom(row[DriverSettlementsDbFields.movementDate]),
          direction: isAdvance
              ? DriverSettlementItemDirection.driverToCompany
              : DriverSettlementItemDirection.companyToDriver,
          amount: amount,
          labelKey: isAdvance ? _labelAdvance : _labelDeduction,
          descriptionKey: row[DriverSettlementsDbFields.notes] as String?,
          metadata: {
            DriverSettlementsDbFields.movementType: type,
            DriverSettlementsDbFields.tripId:
                row[DriverSettlementsDbFields.tripId],
          },
        ),
      );
    }

    var driverPaidTripExpensesTotal = 0.0;
    for (final row in tripExpenseRows) {
      final amount = _amountFrom(row[DriverSettlementsDbFields.amount]);
      driverPaidTripExpensesTotal += amount;
      sourceItems.add(
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
            DriverSettlementsDbFields.paidBy:
                row[DriverSettlementsDbFields.paidBy],
            DriverSettlementsDbFields.tripId:
                row[DriverSettlementsDbFields.tripId],
            DriverSettlementsDbFields.notes:
                row[DriverSettlementsDbFields.notes],
          },
        ),
      );
    }

    return DriverSettlementSourceSnapshot(
      openingDriverBalance: _money(openingDriverBalance),
      advancesTotal: _money(advancesTotal),
      driverPaidTripExpensesTotal: _money(driverPaidTripExpensesTotal),
      deductionsTotal: _money(deductionsTotal),
      sourceItems: sourceItems,
    );
  }

  Future<double> _getOpeningDriverBalance({
    required String companyId,
    required String driverId,
    required DriverSettlementPeriod period,
  }) async {
    final previous = await client
        .from(DriverSettlementsDbTables.driverSettlements)
        .select(DriverSettlementsDbFields.closingDriverBalance)
        .eq(DbCommonFields.companyId, companyId)
        .eq(DriverSettlementsDbFields.driverId, driverId)
        .eq(DriverSettlementsDbFields.status, 'finalized')
        .lt(DriverSettlementsDbFields.periodEnd, _dateOnly(period.start))
        .order(DriverSettlementsDbFields.periodEnd, ascending: false)
        .limit(1);

    if (previous.isNotEmpty) {
      final row = Map<String, dynamic>.from(previous.first);
      return _amountFrom(row[DriverSettlementsDbFields.closingDriverBalance]);
    }

    return _calculateHistoricalOpeningBalance(
      companyId: companyId,
      driverId: driverId,
      before: period.start,
    );
  }

  Future<double> _calculateHistoricalOpeningBalance({
    required String companyId,
    required String driverId,
    required DateTime before,
  }) async {
    final movementRows = await _getDriverFinancialMovementRows(
      companyId: companyId,
      driverId: driverId,
      endExclusive: before,
    );
    final tripExpenseRows = await _getDriverPaidTripExpenseRows(
      companyId: companyId,
      driverId: driverId,
      endExclusive: before,
    );

    var advancesTotal = 0.0;
    var deductionsTotal = 0.0;
    for (final row in movementRows) {
      final type = row[DriverSettlementsDbFields.movementType]?.toString();
      final amount = _amountFrom(row[DriverSettlementsDbFields.amount]);
      if (type == _movementTypeAdvance) {
        advancesTotal += amount;
      } else if (type == _movementTypeDeduction) {
        deductionsTotal += amount;
      }
    }

    final driverPaidTripExpensesTotal = tripExpenseRows.fold<double>(
      0,
      (total, row) =>
          total + _amountFrom(row[DriverSettlementsDbFields.amount]),
    );

    return _money(
      advancesTotal - deductionsTotal - driverPaidTripExpensesTotal,
    );
  }

  Future<List<Map<String, dynamic>>> _getDriverFinancialMovementRows({
    required String companyId,
    required String driverId,
    DateTime? startInclusive,
    DateTime? endInclusive,
    DateTime? endExclusive,
  }) async {
    var query = client
        .from(DriverSettlementsDbTables.driverFinancialMovements)
        .select(_driverFinancialMovementColumns)
        .eq(DbCommonFields.companyId, companyId)
        .eq(DriverSettlementsDbFields.driverId, driverId);

    if (startInclusive != null) {
      query = query.gte(
        DriverSettlementsDbFields.movementDate,
        _dateOnly(startInclusive),
      );
    }
    if (endInclusive != null) {
      query = query.lte(
        DriverSettlementsDbFields.movementDate,
        _dateOnly(endInclusive),
      );
    }
    if (endExclusive != null) {
      query = query.lt(
        DriverSettlementsDbFields.movementDate,
        _dateOnly(endExclusive),
      );
    }

    final rows = await query
        .order(DriverSettlementsDbFields.movementDate)
        .order(DbCommonFields.createdAt);
    return rows.map((row) => Map<String, dynamic>.from(row)).toList();
  }

  Future<List<Map<String, dynamic>>> _getDriverPaidTripExpenseRows({
    required String companyId,
    required String driverId,
    DateTime? startInclusive,
    DateTime? endInclusive,
    DateTime? endExclusive,
  }) async {
    final tripIds = await _getDriverTripIds(
      companyId: companyId,
      driverId: driverId,
    );
    if (tripIds.isEmpty) return const [];

    var query = client
        .from(DriverSettlementsDbTables.tripExpenses)
        .select(_tripExpenseColumns)
        .eq(DbCommonFields.companyId, companyId)
        .inFilter(DriverSettlementsDbFields.tripId, tripIds)
        .inFilter(DriverSettlementsDbFields.paidBy, const [
          _paidByDriverAdvance,
          _paidByDriverCash,
        ]);

    if (startInclusive != null) {
      query = query.gte(
        DriverSettlementsDbFields.expenseDate,
        _dateOnly(startInclusive),
      );
    }
    if (endInclusive != null) {
      query = query.lte(
        DriverSettlementsDbFields.expenseDate,
        _dateOnly(endInclusive),
      );
    }
    if (endExclusive != null) {
      query = query.lt(
        DriverSettlementsDbFields.expenseDate,
        _dateOnly(endExclusive),
      );
    }

    final rows = await query
        .order(DriverSettlementsDbFields.expenseDate)
        .order(DbCommonFields.createdAt);
    return rows.map((row) => Map<String, dynamic>.from(row)).toList();
  }

  Future<List<String>> _getDriverTripIds({
    required String companyId,
    required String driverId,
  }) async {
    final rows = await client
        .from(DriverSettlementsDbTables.trips)
        .select(DbCommonFields.id)
        .eq(DbCommonFields.companyId, companyId)
        .eq(DriverSettlementsDbFields.driverId, driverId);

    return rows
        .map((row) => Map<String, dynamic>.from(row)[DbCommonFields.id])
        .whereType<String>()
        .toList();
  }

  double _amountFrom(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  DateTime? _dateFrom(Object? value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  String _dateOnly(DateTime value) {
    final utc = value.toUtc();
    return '${utc.year.toString().padLeft(4, '0')}-'
        '${utc.month.toString().padLeft(2, '0')}-'
        '${utc.day.toString().padLeft(2, '0')}';
  }

  double _money(double value) {
    return (value * 100).roundToDouble() / 100;
  }
}
