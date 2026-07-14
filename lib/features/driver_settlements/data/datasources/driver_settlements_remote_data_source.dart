import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/data/constants/db_common_fields.dart';
import '../../domain/entities/driver_settlement_period.dart';
import '../../domain/entities/driver_settlement_source_snapshot.dart';
import '../../domain/entities/driver_settlement_write_data.dart';
import '../constants/driver_settlements_db_fields.dart';
import '../mappers/driver_settlement_mapper.dart';
import '../models/driver_settlement_driver_option_model.dart';
import '../models/driver_settlement_item_model.dart';
import '../models/driver_settlement_model.dart';
import 'driver_settlement_source_snapshot_loader.dart';

const _driverSettlementColumns = '''
id,
company_id,
driver_id,
period_start,
period_end,
opening_driver_balance,
advances_total,
driver_paid_trip_expenses_total,
returned_cash_total,
deductions_total,
settlement_deductions_total,
gross_salary,
salary_deductions_total,
balance_deduction_applied,
net_salary_payable,
closing_driver_balance,
status,
notes,
finalized_at,
finalized_by,
voided_at,
voided_by,
void_reason,
created_by,
updated_by,
created_at,
updated_at
''';

const _driverSettlementItemColumns = '''
id,
company_id,
settlement_id,
source_type,
source_id,
source_date,
direction,
amount,
label_key,
description_key,
metadata,
created_at
''';

const _driverOptionColumns =
    '''
${DbCommonFields.id},
${DriverSettlementsDbFields.fullName},
${DriverSettlementsDbFields.isActive}
''';

abstract class DriverSettlementsRemoteDataSource {
  Future<List<DriverSettlementModel>> getDriverSettlements({
    required String companyId,
    String? driverId,
    bool includeVoided = false,
  });

  Future<List<DriverSettlementDriverOptionModel>> getDriverOptions({
    required String companyId,
  });

  Future<DriverSettlementDriverOptionModel?> getDriverOptionById({
    required String companyId,
    required String driverId,
  });

  Future<DriverSettlementModel> getDriverSettlementById({
    required String companyId,
    required String settlementId,
  });

  Future<DriverSettlementSourceSnapshot> getSettlementSourceSnapshot({
    required String companyId,
    required String driverId,
    required DriverSettlementPeriod period,
  });

  Future<DriverSettlementModel> createDraft({
    required DriverSettlementDraftWriteData data,
  });

  Future<DriverSettlementModel> finalizeSettlement({
    required DriverSettlementFinalizeData data,
  });

  Future<DriverSettlementModel> voidSettlement({
    required DriverSettlementVoidData data,
  });
}

class SupabaseDriverSettlementsRemoteDataSource
    implements DriverSettlementsRemoteDataSource {
  final SupabaseClient client;
  final DriverSettlementSourceSnapshotLoader sourceSnapshotLoader;

  SupabaseDriverSettlementsRemoteDataSource(this.client)
    : sourceSnapshotLoader = DriverSettlementSourceSnapshotLoader(client);

  @override
  Future<List<DriverSettlementModel>> getDriverSettlements({
    required String companyId,
    String? driverId,
    bool includeVoided = false,
  }) async {
    var query = client
        .from(DriverSettlementsDbTables.driverSettlements)
        .select(_driverSettlementColumns)
        .eq(DbCommonFields.companyId, companyId);

    if (driverId != null) {
      query = query.eq(DriverSettlementsDbFields.driverId, driverId);
    }

    if (!includeVoided) {
      query = query.neq(DriverSettlementsDbFields.status, 'voided');
    }

    final rows = await query
        .order(DriverSettlementsDbFields.periodEnd, ascending: false)
        .order(DbCommonFields.createdAt, ascending: false);

    return rows
        .map(
          (row) =>
              DriverSettlementModel.fromMap(Map<String, dynamic>.from(row)),
        )
        .toList();
  }

  @override
  Future<List<DriverSettlementDriverOptionModel>> getDriverOptions({
    required String companyId,
  }) async {
    final rows = await client
        .from(DriverSettlementsDbTables.drivers)
        .select(_driverOptionColumns)
        .eq(DbCommonFields.companyId, companyId)
        .order(DriverSettlementsDbFields.isActive, ascending: false)
        .order(DriverSettlementsDbFields.fullName);

    return rows
        .map(
          (row) => DriverSettlementDriverOptionModel.fromMap(
            Map<String, dynamic>.from(row),
          ),
        )
        .toList();
  }

  @override
  Future<DriverSettlementDriverOptionModel?> getDriverOptionById({
    required String companyId,
    required String driverId,
  }) async {
    final rows = await client
        .from(DriverSettlementsDbTables.drivers)
        .select(_driverOptionColumns)
        .eq(DbCommonFields.companyId, companyId)
        .eq(DbCommonFields.id, driverId)
        .limit(1);

    if (rows.isEmpty) return null;
    return DriverSettlementDriverOptionModel.fromMap(
      Map<String, dynamic>.from(rows.first),
    );
  }

  @override
  Future<DriverSettlementModel> getDriverSettlementById({
    required String companyId,
    required String settlementId,
  }) async {
    final row = await client
        .from(DriverSettlementsDbTables.driverSettlements)
        .select(_driverSettlementColumns)
        .eq(DbCommonFields.companyId, companyId)
        .eq(DbCommonFields.id, settlementId)
        .single();

    final items = await _getSettlementItems(
      companyId: companyId,
      settlementId: settlementId,
    );

    return DriverSettlementModel.fromMap(
      Map<String, dynamic>.from(row),
      items: items,
    );
  }

  @override
  Future<DriverSettlementSourceSnapshot> getSettlementSourceSnapshot({
    required String companyId,
    required String driverId,
    required DriverSettlementPeriod period,
  }) {
    return sourceSnapshotLoader.load(
      companyId: companyId,
      driverId: driverId,
      period: period,
    );
  }

  @override
  Future<DriverSettlementModel> createDraft({
    required DriverSettlementDraftWriteData data,
  }) async {
    final row = await client
        .from(DriverSettlementsDbTables.driverSettlements)
        .insert(data.toInsertMap())
        .select(_driverSettlementColumns)
        .single();

    final model = DriverSettlementModel.fromMap(Map<String, dynamic>.from(row));
    if (data.items.isNotEmpty) {
      final itemRows = data.items
          .map((item) => item.toInsertMap(settlementId: model.id))
          .toList();
      await client
          .from(DriverSettlementsDbTables.driverSettlementItems)
          .insert(itemRows);
    }

    return getDriverSettlementById(
      companyId: data.companyId,
      settlementId: model.id,
    );
  }

  @override
  Future<DriverSettlementModel> finalizeSettlement({
    required DriverSettlementFinalizeData data,
  }) async {
    final actorUserId = client.auth.currentUser?.id;
    final row = await client
        .from(DriverSettlementsDbTables.driverSettlements)
        .update(data.toUpdateMap(actorUserId: actorUserId))
        .eq(DbCommonFields.companyId, data.companyId)
        .eq(DbCommonFields.id, data.settlementId)
        .select(_driverSettlementColumns)
        .single();

    final items = await _getSettlementItems(
      companyId: data.companyId,
      settlementId: data.settlementId,
    );
    return DriverSettlementModel.fromMap(
      Map<String, dynamic>.from(row),
      items: items,
    );
  }

  @override
  Future<DriverSettlementModel> voidSettlement({
    required DriverSettlementVoidData data,
  }) async {
    final actorUserId = client.auth.currentUser?.id;
    final row = await client
        .from(DriverSettlementsDbTables.driverSettlements)
        .update(data.toUpdateMap(actorUserId: actorUserId))
        .eq(DbCommonFields.companyId, data.companyId)
        .eq(DbCommonFields.id, data.settlementId)
        .select(_driverSettlementColumns)
        .single();

    final items = await _getSettlementItems(
      companyId: data.companyId,
      settlementId: data.settlementId,
    );
    return DriverSettlementModel.fromMap(
      Map<String, dynamic>.from(row),
      items: items,
    );
  }

  Future<List<DriverSettlementItemModel>> _getSettlementItems({
    required String companyId,
    required String settlementId,
  }) async {
    final rows = await client
        .from(DriverSettlementsDbTables.driverSettlementItems)
        .select(_driverSettlementItemColumns)
        .eq(DbCommonFields.companyId, companyId)
        .eq(DriverSettlementsDbFields.settlementId, settlementId)
        .order(DriverSettlementsDbFields.sourceDate)
        .order(DbCommonFields.createdAt);

    return rows
        .map(
          (row) =>
              DriverSettlementItemModel.fromMap(Map<String, dynamic>.from(row)),
        )
        .toList();
  }
}
