import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/data/constants/db_common_fields.dart';
import '../constants/driver_finance_db_fields.dart';
import '../mappers/driver_balance_mapper.dart';
import '../models/driver_balance_model.dart';
import '../utils/driver_balance_source_selector.dart';

const _driverFinancialMovementColumns = '''
id,
company_id,
driver_id,
trip_id,
movement_type,
amount,
movement_date,
notes,
created_at,
updated_at
''';

const _tripExpenseColumns = '''
id,
company_id,
trip_id,
amount,
paid_by,
expense_date,
created_at
''';

abstract class CanonicalDriverBalanceRemoteDataSource {
  Future<DriverBalanceModel> getCanonicalDriverBalance({
    required String companyId,
    required String driverId,
    required DateTime beforeExclusive,
    DateTime? checkpointBeforeExclusive,
  });
}

class SupabaseCanonicalDriverBalanceRemoteDataSource
    implements CanonicalDriverBalanceRemoteDataSource {
  final SupabaseClient client;
  final DriverBalanceSourceMapper balanceSourceMapper;
  final DriverBalanceSourceSelector sourceSelector;

  const SupabaseCanonicalDriverBalanceRemoteDataSource(
    this.client, {
    this.balanceSourceMapper = const DriverBalanceSourceMapper(),
    this.sourceSelector = const DriverBalanceSourceSelector(),
  });

  @override
  Future<DriverBalanceModel> getCanonicalDriverBalance({
    required String companyId,
    required String driverId,
    required DateTime beforeExclusive,
    DateTime? checkpointBeforeExclusive,
  }) async {
    final checkpointRow = await _getBalanceCheckpoint(
      companyId: companyId,
      driverId: driverId,
      checkpointBeforeExclusive: checkpointBeforeExclusive,
    );
    final movementRows = await _getMovementRows(
      companyId: companyId,
      driverId: driverId,
      beforeExclusive: beforeExclusive,
      checkpointRow: checkpointRow,
    );
    final tripExpenseRows = await _getTripExpenseRows(
      companyId: companyId,
      driverId: driverId,
      beforeExclusive: beforeExclusive,
      checkpointRow: checkpointRow,
    );

    return balanceSourceMapper.map(
      companyId: companyId,
      driverId: driverId,
      checkpointRow: checkpointRow,
      movementRows: movementRows,
      tripExpenseRows: tripExpenseRows,
    );
  }

  Future<Map<String, dynamic>?> _getBalanceCheckpoint({
    required String companyId,
    required String driverId,
    required DateTime? checkpointBeforeExclusive,
  }) async {
    final response = await client.rpc(
      DriverFinanceDbFunctions.getBalanceCheckpoint,
      params: {
        DriverFinanceDbFields.parameterCompanyId: companyId,
        DriverFinanceDbFields.parameterDriverId: driverId,
        DriverFinanceDbFields.parameterBeforeExclusive:
            checkpointBeforeExclusive == null
            ? null
            : _dateOnly(checkpointBeforeExclusive),
      },
    );

    if (response is List && response.isNotEmpty) {
      return Map<String, dynamic>.from(response.first as Map);
    }
    if (response is Map && response.isNotEmpty) {
      return Map<String, dynamic>.from(response);
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> _getMovementRows({
    required String companyId,
    required String driverId,
    required DateTime beforeExclusive,
    required Map<String, dynamic>? checkpointRow,
  }) async {
    final before = _dateOnly(beforeExclusive);
    if (checkpointRow == null) {
      final rows = await client
          .from(DriverFinanceDbTables.driverFinancialMovements)
          .select(_driverFinancialMovementColumns)
          .eq(DbCommonFields.companyId, companyId)
          .eq(DriverFinanceDbFields.driverId, driverId)
          .lt(DriverFinanceDbFields.movementDate, before)
          .order(DriverFinanceDbFields.movementDate)
          .order(DbCommonFields.createdAt)
          .order(DbCommonFields.id);
      return sourceSelector.select(
        rows: _maps(rows),
        effectiveDateField: DriverFinanceDbFields.movementDate,
        beforeExclusive: beforeExclusive,
      );
    }

    final checkpointPeriodEnd = _requiredDate(
      checkpointRow[DriverFinanceDbFields.checkpointPeriodEnd],
    );
    final snapshotCreatedAt = _requiredDate(
      checkpointRow[DriverFinanceDbFields.checkpointSnapshotCreatedAt],
    );

    final effectiveRows = await client
        .from(DriverFinanceDbTables.driverFinancialMovements)
        .select(_driverFinancialMovementColumns)
        .eq(DbCommonFields.companyId, companyId)
        .eq(DriverFinanceDbFields.driverId, driverId)
        .gt(DriverFinanceDbFields.movementDate, _dateOnly(checkpointPeriodEnd))
        .lt(DriverFinanceDbFields.movementDate, before)
        .order(DriverFinanceDbFields.movementDate)
        .order(DbCommonFields.createdAt)
        .order(DbCommonFields.id);

    final lateRows = await client
        .from(DriverFinanceDbTables.driverFinancialMovements)
        .select(_driverFinancialMovementColumns)
        .eq(DbCommonFields.companyId, companyId)
        .eq(DriverFinanceDbFields.driverId, driverId)
        .gt(
          DbCommonFields.createdAt,
          snapshotCreatedAt.toUtc().toIso8601String(),
        )
        .lt(DriverFinanceDbFields.movementDate, before)
        .order(DriverFinanceDbFields.movementDate)
        .order(DbCommonFields.createdAt)
        .order(DbCommonFields.id);

    return sourceSelector.select(
      rows: [..._maps(effectiveRows), ..._maps(lateRows)],
      effectiveDateField: DriverFinanceDbFields.movementDate,
      beforeExclusive: beforeExclusive,
      checkpointPeriodEnd: checkpointPeriodEnd,
      checkpointSnapshotCreatedAt: snapshotCreatedAt,
    );
  }

  Future<List<Map<String, dynamic>>> _getTripExpenseRows({
    required String companyId,
    required String driverId,
    required DateTime beforeExclusive,
    required Map<String, dynamic>? checkpointRow,
  }) async {
    final tripIds = await _getDriverTripIds(
      companyId: companyId,
      driverId: driverId,
    );
    if (tripIds.isEmpty) return const [];

    final before = _dateOnly(beforeExclusive);
    if (checkpointRow == null) {
      final rows = await client
          .from(DriverFinanceDbTables.tripExpenses)
          .select(_tripExpenseColumns)
          .eq(DbCommonFields.companyId, companyId)
          .inFilter(DriverFinanceDbFields.tripId, tripIds)
          .inFilter(DriverFinanceDbFields.paidBy, const [
            DriverFinanceDbValues.paidByDriverAdvance,
            DriverFinanceDbValues.paidByDriverCash,
          ])
          .lt(DriverFinanceDbFields.expenseDate, before)
          .order(DriverFinanceDbFields.expenseDate)
          .order(DbCommonFields.createdAt)
          .order(DbCommonFields.id);
      return sourceSelector.select(
        rows: _maps(rows),
        effectiveDateField: DriverFinanceDbFields.expenseDate,
        beforeExclusive: beforeExclusive,
      );
    }

    final checkpointPeriodEnd = _requiredDate(
      checkpointRow[DriverFinanceDbFields.checkpointPeriodEnd],
    );
    final snapshotCreatedAt = _requiredDate(
      checkpointRow[DriverFinanceDbFields.checkpointSnapshotCreatedAt],
    );

    final effectiveRows = await client
        .from(DriverFinanceDbTables.tripExpenses)
        .select(_tripExpenseColumns)
        .eq(DbCommonFields.companyId, companyId)
        .inFilter(DriverFinanceDbFields.tripId, tripIds)
        .inFilter(DriverFinanceDbFields.paidBy, const [
          DriverFinanceDbValues.paidByDriverAdvance,
          DriverFinanceDbValues.paidByDriverCash,
        ])
        .gt(DriverFinanceDbFields.expenseDate, _dateOnly(checkpointPeriodEnd))
        .lt(DriverFinanceDbFields.expenseDate, before)
        .order(DriverFinanceDbFields.expenseDate)
        .order(DbCommonFields.createdAt)
        .order(DbCommonFields.id);

    final lateRows = await client
        .from(DriverFinanceDbTables.tripExpenses)
        .select(_tripExpenseColumns)
        .eq(DbCommonFields.companyId, companyId)
        .inFilter(DriverFinanceDbFields.tripId, tripIds)
        .inFilter(DriverFinanceDbFields.paidBy, const [
          DriverFinanceDbValues.paidByDriverAdvance,
          DriverFinanceDbValues.paidByDriverCash,
        ])
        .gt(
          DbCommonFields.createdAt,
          snapshotCreatedAt.toUtc().toIso8601String(),
        )
        .lt(DriverFinanceDbFields.expenseDate, before)
        .order(DriverFinanceDbFields.expenseDate)
        .order(DbCommonFields.createdAt)
        .order(DbCommonFields.id);

    return sourceSelector.select(
      rows: [..._maps(effectiveRows), ..._maps(lateRows)],
      effectiveDateField: DriverFinanceDbFields.expenseDate,
      beforeExclusive: beforeExclusive,
      checkpointPeriodEnd: checkpointPeriodEnd,
      checkpointSnapshotCreatedAt: snapshotCreatedAt,
    );
  }

  Future<List<String>> _getDriverTripIds({
    required String companyId,
    required String driverId,
  }) async {
    final rows = await client
        .from(DriverFinanceDbTables.trips)
        .select(DbCommonFields.id)
        .eq(DbCommonFields.companyId, companyId)
        .eq(DriverFinanceDbFields.driverId, driverId);

    return rows
        .map((row) => Map<String, dynamic>.from(row)[DbCommonFields.id])
        .whereType<String>()
        .toList(growable: false);
  }

  List<Map<String, dynamic>> _maps(Iterable<dynamic> rows) {
    return rows.map((row) => Map<String, dynamic>.from(row as Map)).toList();
  }

  DateTime _requiredDate(Object? value) {
    final parsed = DateTime.tryParse(value?.toString() ?? '');
    if (parsed == null) throw FormatException('Invalid date value: $value');
    return parsed;
  }

  String _dateOnly(DateTime value) {
    return '${value.year.toString().padLeft(4, '0')}-'
        '${value.month.toString().padLeft(2, '0')}-'
        '${value.day.toString().padLeft(2, '0')}';
  }
}
