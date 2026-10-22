import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/data/constants/db_common_fields.dart';
import '../../../../core/data/utils/db_date.dart';
import '../../../../core/data/utils/db_timestamp.dart';
import '../../../../core/domain/value_objects/business_date.dart';
import '../constants/driver_finance_db_fields.dart';
import '../mappers/driver_balance_mapper.dart';
import '../mappers/driver_balance_activity_mapper.dart';
import '../../domain/entities/driver_balance_activity.dart';
import '../mappers/driver_money_balance_mapper.dart';
import '../models/driver_balance_model.dart';
import '../models/driver_money_balance_model.dart';
import '../utils/driver_balance_source_selector.dart';

const _driverFinancialMovementColumns = '''
id,
company_id,
driver_id,
trip_id,
movement_type,
amount,
amount_minor_units,
currency_code,
currency_fraction_digits,
movement_date,
notes,
created_at,
updated_at
''';

const _expenseLedgerColumns = '''
id,
company_id,
trip_id,
amount_minor_units,
currency_code,
currency_fraction_digits,
funding_source,
description,
notes,
expense_date,
is_voided,
origin_kind,
origin_id,
created_at
''';

abstract class CanonicalDriverBalanceRemoteDataSource {
  Future<DriverBalanceModel> getCanonicalDriverBalance({
    required String companyId,
    required String driverId,
    required BusinessDate beforeExclusive,
    BusinessDate? checkpointBeforeExclusive,
  });

  Future<DriverMoneyBalanceModel> getCanonicalDriverMoneyBalance({
    required String companyId,
    required String driverId,
    required String currencyCode,
    required int currencyFractionDigits,
    required BusinessDate beforeExclusive,
    BusinessDate? checkpointBeforeExclusive,
  });
}

abstract class DriverBalanceActivityRemoteDataSource {
  Future<DriverBalanceActivity> getDriverBalanceActivity({
    required String companyId,
    required String driverId,
    required String currencyCode,
    required int currencyFractionDigits,
    required BusinessDate beforeExclusive,
    BusinessDate? checkpointBeforeExclusive,
  });
}

class SupabaseCanonicalDriverBalanceRemoteDataSource
    implements CanonicalDriverBalanceRemoteDataSource,
        DriverBalanceActivityRemoteDataSource {
  final SupabaseClient client;
  final DriverBalanceSourceMapper balanceSourceMapper;
  final DriverMoneyBalanceSourceMapper moneyBalanceSourceMapper;
  final DriverBalanceSourceSelector sourceSelector;
  final DriverBalanceActivityMapper activityMapper;

  const SupabaseCanonicalDriverBalanceRemoteDataSource(
    this.client, {
    this.balanceSourceMapper = const DriverBalanceSourceMapper(),
    this.moneyBalanceSourceMapper = const DriverMoneyBalanceSourceMapper(),
    this.sourceSelector = const DriverBalanceSourceSelector(),
    this.activityMapper = const DriverBalanceActivityMapper(),
  });

  @override
  Future<DriverBalanceModel> getCanonicalDriverBalance({
    required String companyId,
    required String driverId,
    required BusinessDate beforeExclusive,
    BusinessDate? checkpointBeforeExclusive,
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
    final expenseLedgerRows = await _getExpenseLedgerRows(
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
      expenseLedgerRows: expenseLedgerRows,
    );
  }

  @override
  Future<DriverMoneyBalanceModel> getCanonicalDriverMoneyBalance({
    required String companyId,
    required String driverId,
    required String currencyCode,
    required int currencyFractionDigits,
    required BusinessDate beforeExclusive,
    BusinessDate? checkpointBeforeExclusive,
  }) async {
    final checkpointRow = await _getBalanceCheckpointV2(
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
    final expenseLedgerRows = await _getExpenseLedgerRows(
      companyId: companyId,
      driverId: driverId,
      beforeExclusive: beforeExclusive,
      checkpointRow: checkpointRow,
    );

    return moneyBalanceSourceMapper.map(
      companyId: companyId,
      driverId: driverId,
      currencyCode: currencyCode,
      currencyFractionDigits: currencyFractionDigits,
      checkpointRow: checkpointRow,
      movementRows: movementRows,
      expenseLedgerRows: expenseLedgerRows,
    );
  }

  /// Uses exactly the same checkpoint and selected source rows as the
  /// canonical Money balance. No copy of the selection rules is introduced.
  @override
  Future<DriverBalanceActivity> getDriverBalanceActivity({
    required String companyId,
    required String driverId,
    required String currencyCode,
    required int currencyFractionDigits,
    required BusinessDate beforeExclusive,
    BusinessDate? checkpointBeforeExclusive,
  }) async {
    final checkpointRow = await _getBalanceCheckpointV2(
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
    final expenseLedgerRows = await _getExpenseLedgerRows(
      companyId: companyId,
      driverId: driverId,
      beforeExclusive: beforeExclusive,
      checkpointRow: checkpointRow,
    );
    return activityMapper.map(
      companyId: companyId,
      driverId: driverId,
      currencyCode: currencyCode,
      currencyFractionDigits: currencyFractionDigits,
      checkpointRow: checkpointRow,
      movementRows: movementRows,
      expenseLedgerRows: expenseLedgerRows,
    );
  }

  Future<Map<String, dynamic>?> _getBalanceCheckpoint({
    required String companyId,
    required String driverId,
    required BusinessDate? checkpointBeforeExclusive,
  }) {
    return _getBalanceCheckpointByFunction(
      functionName: DriverFinanceDbFunctions.getBalanceCheckpoint,
      companyId: companyId,
      driverId: driverId,
      checkpointBeforeExclusive: checkpointBeforeExclusive,
    );
  }

  Future<Map<String, dynamic>?> _getBalanceCheckpointV2({
    required String companyId,
    required String driverId,
    required BusinessDate? checkpointBeforeExclusive,
  }) {
    return _getBalanceCheckpointByFunction(
      functionName: DriverFinanceDbFunctions.getBalanceCheckpointV2,
      companyId: companyId,
      driverId: driverId,
      checkpointBeforeExclusive: checkpointBeforeExclusive,
    );
  }

  Future<Map<String, dynamic>?> _getBalanceCheckpointByFunction({
    required String functionName,
    required String companyId,
    required String driverId,
    required BusinessDate? checkpointBeforeExclusive,
  }) async {
    final response = await client.rpc(
      functionName,
      params: {
        DriverFinanceDbFields.parameterCompanyId: companyId,
        DriverFinanceDbFields.parameterDriverId: driverId,
        DriverFinanceDbFields.parameterBeforeExclusive:
            checkpointBeforeExclusive == null
            ? null
            : DbDate.encode(checkpointBeforeExclusive),
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
    required BusinessDate beforeExclusive,
    required Map<String, dynamic>? checkpointRow,
  }) async {
    final before = DbDate.encode(beforeExclusive);
    if (checkpointRow == null) {
      final rows = await _readAllPages((from, to) async {
        final page = await client
            .from(DriverFinanceDbTables.driverFinancialMovements)
            .select(_driverFinancialMovementColumns)
            .eq(DbCommonFields.companyId, companyId)
            .eq(DriverFinanceDbFields.driverId, driverId)
            .lt(DriverFinanceDbFields.movementDate, before)
            .order(DriverFinanceDbFields.movementDate)
            .order(DbCommonFields.createdAt)
            .order(DbCommonFields.id)
            .range(from, to);
        return _maps(page);
      });
      return sourceSelector.select(
        rows: rows,
        effectiveDateField: DriverFinanceDbFields.movementDate,
        beforeExclusive: beforeExclusive,
      );
    }

    final checkpointPeriodEnd = DbDate.decode(
      checkpointRow[DriverFinanceDbFields.checkpointPeriodEnd],
      field: DriverFinanceDbFields.checkpointPeriodEnd,
    );
    final snapshotCreatedAt = DbTimestamp.decode(
      checkpointRow[DriverFinanceDbFields.checkpointSnapshotCreatedAt],
      field: DriverFinanceDbFields.checkpointSnapshotCreatedAt,
    );

    final effectiveRows = await _readAllPages((from, to) async {
      final page = await client
        .from(DriverFinanceDbTables.driverFinancialMovements)
        .select(_driverFinancialMovementColumns)
        .eq(DbCommonFields.companyId, companyId)
        .eq(DriverFinanceDbFields.driverId, driverId)
        .gt(
          DriverFinanceDbFields.movementDate,
          DbDate.encode(checkpointPeriodEnd),
        )
        .lt(DriverFinanceDbFields.movementDate, before)
        .order(DriverFinanceDbFields.movementDate)
        .order(DbCommonFields.createdAt)
        .order(DbCommonFields.id)
          .range(from, to);
      return _maps(page);
    });

    final lateRows = await _readAllPages((from, to) async {
      final page = await client
        .from(DriverFinanceDbTables.driverFinancialMovements)
        .select(_driverFinancialMovementColumns)
        .eq(DbCommonFields.companyId, companyId)
        .eq(DriverFinanceDbFields.driverId, driverId)
        .gt(DbCommonFields.createdAt, DbTimestamp.encode(snapshotCreatedAt))
        .lt(DriverFinanceDbFields.movementDate, before)
        .order(DriverFinanceDbFields.movementDate)
        .order(DbCommonFields.createdAt)
        .order(DbCommonFields.id)
          .range(from, to);
      return _maps(page);
    });

    return sourceSelector.select(
      rows: [...effectiveRows, ...lateRows],
      effectiveDateField: DriverFinanceDbFields.movementDate,
      beforeExclusive: beforeExclusive,
      checkpointPeriodEnd: checkpointPeriodEnd,
      checkpointSnapshotCreatedAt: snapshotCreatedAt,
    );
  }

  Future<List<Map<String, dynamic>>> _getExpenseLedgerRows({
    required String companyId,
    required String driverId,
    required BusinessDate beforeExclusive,
    required Map<String, dynamic>? checkpointRow,
  }) async {
    final tripIds = await _getDriverTripIds(
      companyId: companyId,
      driverId: driverId,
    );
    if (tripIds.isEmpty) return const [];

    final before = DbDate.encode(beforeExclusive);
    if (checkpointRow == null) {
      final rows = await _readAllPages((from, to) async {
        final page = await client
            .from(DriverFinanceDbTables.expenseLedgerEntries)
            .select(_expenseLedgerColumns)
            .eq(DbCommonFields.companyId, companyId)
            .eq(DriverFinanceDbFields.isVoided, false)
            .inFilter(DriverFinanceDbFields.tripId, tripIds)
            .inFilter(DriverFinanceDbFields.fundingSource, const [
              DriverFinanceDbValues.paidByDriverAdvance,
              DriverFinanceDbValues.paidByDriverCash,
            ])
            .lt(DriverFinanceDbFields.expenseDate, before)
            .order(DriverFinanceDbFields.expenseDate)
            .order(DbCommonFields.createdAt)
            .order(DbCommonFields.id)
            .range(from, to);
        return _maps(page);
      });
      return sourceSelector.select(
        rows: rows,
        effectiveDateField: DriverFinanceDbFields.expenseDate,
        beforeExclusive: beforeExclusive,
      );
    }

    final checkpointPeriodEnd = DbDate.decode(
      checkpointRow[DriverFinanceDbFields.checkpointPeriodEnd],
      field: DriverFinanceDbFields.checkpointPeriodEnd,
    );
    final snapshotCreatedAt = DbTimestamp.decode(
      checkpointRow[DriverFinanceDbFields.checkpointSnapshotCreatedAt],
      field: DriverFinanceDbFields.checkpointSnapshotCreatedAt,
    );

    final effectiveRows = await _readAllPages((from, to) async {
      final page = await client
        .from(DriverFinanceDbTables.expenseLedgerEntries)
        .select(_expenseLedgerColumns)
        .eq(DbCommonFields.companyId, companyId)
        .eq(DriverFinanceDbFields.isVoided, false)
        .inFilter(DriverFinanceDbFields.tripId, tripIds)
        .inFilter(DriverFinanceDbFields.fundingSource, const [
          DriverFinanceDbValues.paidByDriverAdvance,
          DriverFinanceDbValues.paidByDriverCash,
        ])
        .gt(
          DriverFinanceDbFields.expenseDate,
          DbDate.encode(checkpointPeriodEnd),
        )
        .lt(DriverFinanceDbFields.expenseDate, before)
        .order(DriverFinanceDbFields.expenseDate)
        .order(DbCommonFields.createdAt)
        .order(DbCommonFields.id)
          .range(from, to);
      return _maps(page);
    });

    final lateRows = await _readAllPages((from, to) async {
      final page = await client
        .from(DriverFinanceDbTables.expenseLedgerEntries)
        .select(_expenseLedgerColumns)
        .eq(DbCommonFields.companyId, companyId)
        .eq(DriverFinanceDbFields.isVoided, false)
        .inFilter(DriverFinanceDbFields.tripId, tripIds)
        .inFilter(DriverFinanceDbFields.fundingSource, const [
          DriverFinanceDbValues.paidByDriverAdvance,
          DriverFinanceDbValues.paidByDriverCash,
        ])
        .gt(DbCommonFields.createdAt, DbTimestamp.encode(snapshotCreatedAt))
        .lt(DriverFinanceDbFields.expenseDate, before)
        .order(DriverFinanceDbFields.expenseDate)
        .order(DbCommonFields.createdAt)
        .order(DbCommonFields.id)
          .range(from, to);
      return _maps(page);
    });

    return sourceSelector.select(
      rows: [...effectiveRows, ...lateRows],
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
    final rows = await _readAllPages((from, to) async {
      final page = await client
          .from(DriverFinanceDbTables.trips)
          .select(DbCommonFields.id)
          .eq(DbCommonFields.companyId, companyId)
          .eq(DriverFinanceDbFields.driverId, driverId)
          .order(DbCommonFields.id)
          .range(from, to);
      return _maps(page);
    });

    return rows
        .map((row) => Map<String, dynamic>.from(row)[DbCommonFields.id])
        .whereType<String>()
        .toList(growable: false);
  }

  // PostgREST applies row limits even if the query omits a LIMIT clause.
  // Fetch all canonical sources so the balance and visible activity reconcile.
  static const int _pageSize = 500;

  Future<List<Map<String, dynamic>>> _readAllPages(
    Future<List<Map<String, dynamic>>> Function(int from, int to) loadPage,
  ) async {
    final rows = <Map<String, dynamic>>[];
    for (var from = 0;; from += _pageSize) {
      final page = await loadPage(from, from + _pageSize - 1);
      rows.addAll(page);
      if (page.length < _pageSize) return rows;
    }
  }

  List<Map<String, dynamic>> _maps(Iterable<dynamic> rows) {
    return rows.map((row) => Map<String, dynamic>.from(row as Map)).toList();
  }
}
