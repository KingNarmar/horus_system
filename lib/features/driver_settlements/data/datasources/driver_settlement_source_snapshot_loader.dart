import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/data/constants/db_common_fields.dart';
import '../../../../core/data/utils/db_date.dart';
import '../../../../core/domain/value_objects/business_date.dart';
import '../../../../core/domain/value_objects/currency_configuration.dart';
import '../../domain/entities/driver_settlement_money_source_snapshot.dart';
import '../../domain/entities/driver_settlement_period.dart';
import '../../domain/entities/driver_settlement_source_snapshot.dart';
import '../constants/driver_settlement_source_values.dart';
import '../constants/driver_settlements_db_fields.dart';
import '../mappers/driver_settlement_money_source_snapshot_mapper.dart';
import '../mappers/driver_settlement_source_snapshot_mapper.dart';

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
created_at
''';

const _expenseLedgerColumns = '''
id,
company_id,
trip_id,
description,
amount_minor_units,
currency_code,
currency_fraction_digits,
funding_source,
expense_date,
notes,
origin_kind,
origin_id,
created_at
''';

class DriverSettlementSourceSnapshotLoader {
  final SupabaseClient client;
  final DriverSettlementSourceSnapshotMapper snapshotMapper;
  final DriverSettlementMoneySourceSnapshotMapper moneySnapshotMapper;

  const DriverSettlementSourceSnapshotLoader(
    this.client, {
    this.snapshotMapper = const DriverSettlementSourceSnapshotMapper(),
    this.moneySnapshotMapper =
        const DriverSettlementMoneySourceSnapshotMapper(),
  });

  Future<DriverSettlementSourceSnapshot> load({
    required String companyId,
    required String driverId,
    required DriverSettlementPeriod period,
  }) async {
    final sources = await _loadSourceRows(
      companyId: companyId,
      driverId: driverId,
      period: period,
    );
    return snapshotMapper.map(
      companyId: companyId,
      openingDriverBalance: 0,
      movementRows: sources.movementRows,
      tripExpenseRows: sources.tripExpenseRows,
    );
  }

  Future<DriverSettlementMoneySourceSnapshot> loadMoney({
    required String companyId,
    required String driverId,
    required DriverSettlementPeriod period,
    required CurrencyConfiguration currencyConfiguration,
  }) async {
    final sources = await _loadSourceRows(
      companyId: companyId,
      driverId: driverId,
      period: period,
    );
    return moneySnapshotMapper.map(
      companyId: companyId,
      currencyConfiguration: currencyConfiguration,
      movementRows: sources.movementRows,
      tripExpenseRows: sources.tripExpenseRows,
    );
  }

  Future<_SettlementSourceRows> _loadSourceRows({
    required String companyId,
    required String driverId,
    required DriverSettlementPeriod period,
  }) async {
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
    return _SettlementSourceRows(
      movementRows: movementRows,
      tripExpenseRows: tripExpenseRows,
    );
  }

  Future<List<Map<String, dynamic>>> _getDriverFinancialMovementRows({
    required String companyId,
    required String driverId,
    required BusinessDate startInclusive,
    required BusinessDate endInclusive,
  }) async {
    final rows = await client
        .from(DriverSettlementsDbTables.driverFinancialMovements)
        .select(_driverFinancialMovementColumns)
        .eq(DbCommonFields.companyId, companyId)
        .eq(DriverSettlementsDbFields.driverId, driverId)
        .gte(
          DriverSettlementsDbFields.movementDate,
          DbDate.encode(startInclusive),
        )
        .lte(
          DriverSettlementsDbFields.movementDate,
          DbDate.encode(endInclusive),
        )
        .order(DriverSettlementsDbFields.movementDate)
        .order(DbCommonFields.createdAt)
        .order(DbCommonFields.id);

    return rows.map((row) => Map<String, dynamic>.from(row)).toList();
  }

  Future<List<Map<String, dynamic>>> _getDriverPaidTripExpenseRows({
    required String companyId,
    required String driverId,
    required BusinessDate startInclusive,
    required BusinessDate endInclusive,
  }) async {
    final tripIds = await _getDriverTripIds(
      companyId: companyId,
      driverId: driverId,
    );
    if (tripIds.isEmpty) return const [];

    final rows = await client
        .from(DriverSettlementsDbTables.expenseLedgerEntries)
        .select(_expenseLedgerColumns)
        .eq(DbCommonFields.companyId, companyId)
        .eq(DriverSettlementsDbFields.isVoided, false)
        .inFilter(DriverSettlementsDbFields.tripId, tripIds)
        .inFilter(DriverSettlementsDbFields.fundingSource, const [
          DriverSettlementSourceValues.fundingSourceDriverAdvance,
          DriverSettlementSourceValues.fundingSourceDriverCash,
        ])
        .gte(
          DriverSettlementsDbFields.expenseDate,
          DbDate.encode(startInclusive),
        )
        .lte(DriverSettlementsDbFields.expenseDate, DbDate.encode(endInclusive))
        .order(DriverSettlementsDbFields.expenseDate)
        .order(DbCommonFields.createdAt)
        .order(DbCommonFields.id);

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
        .toList(growable: false);
  }
}

final class _SettlementSourceRows {
  final List<Map<String, dynamic>> movementRows;
  final List<Map<String, dynamic>> tripExpenseRows;

  const _SettlementSourceRows({
    required this.movementRows,
    required this.tripExpenseRows,
  });
}
