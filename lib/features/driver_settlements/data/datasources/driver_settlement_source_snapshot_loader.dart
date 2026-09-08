import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/data/constants/db_common_fields.dart';
import '../../../../core/data/utils/db_date.dart';
import '../../../../core/domain/value_objects/business_date.dart';
import '../../domain/entities/driver_settlement_period.dart';
import '../../domain/entities/driver_settlement_source_snapshot.dart';
import '../constants/driver_settlements_db_fields.dart';
import '../mappers/driver_settlement_source_snapshot_mapper.dart';

const _driverFinancialMovementColumns = '''
id,
company_id,
driver_id,
trip_id,
movement_type,
amount,
movement_date,
notes,
created_at
''';

const _tripExpenseColumns = '''
id,
company_id,
trip_id,
expense_name,
amount,
paid_by,
expense_date,
notes,
created_at
''';

const _paidByDriverAdvance = 'driver_advance';
const _paidByDriverCash = 'driver_cash';

class DriverSettlementSourceSnapshotLoader {
  final SupabaseClient client;
  final DriverSettlementSourceSnapshotMapper snapshotMapper;

  const DriverSettlementSourceSnapshotLoader(
    this.client, {
    this.snapshotMapper = const DriverSettlementSourceSnapshotMapper(),
  });

  Future<DriverSettlementSourceSnapshot> load({
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

    return snapshotMapper.map(
      companyId: companyId,
      openingDriverBalance: 0,
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
        .from(DriverSettlementsDbTables.tripExpenses)
        .select(_tripExpenseColumns)
        .eq(DbCommonFields.companyId, companyId)
        .inFilter(DriverSettlementsDbFields.tripId, tripIds)
        .inFilter(DriverSettlementsDbFields.paidBy, const [
          _paidByDriverAdvance,
          _paidByDriverCash,
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
