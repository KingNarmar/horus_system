import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/audit_entity_type.dart';
import '../../domain/entities/audit_log_write_data.dart';
import '../../domain/entities/audit_module.dart';
import '../models/audit_log_model.dart';
import '../../../../core/data/constants/db_common_fields.dart';
import '../constants/audit_db_fields.dart';

abstract class AuditLogsRemoteDataSource {
  Future<void> createAuditLog({required AuditLogWriteData data});

  Future<List<AuditLogModel>> getEntityAuditLogs({
    required String companyId,
    required AuditModule module,
    required AuditEntityType entityType,
    required String entityId,
  });
}

class SupabaseAuditLogsRemoteDataSource implements AuditLogsRemoteDataSource {
  final SupabaseClient _client;

  const SupabaseAuditLogsRemoteDataSource(this._client);

  /// Compatibility verification for legacy repository audit writers.
  ///
  /// Audit persistence is server-owned. Business-table triggers write the
  /// authoritative audit event in the same database mutation. This call never
  /// inserts into [AuditDbFields.tableName]; it only verifies that the expected
  /// event was recorded for the current authenticated actor.
  @override
  Future<void> createAuditLog({required AuditLogWriteData data}) async {
    await _client.rpc(
      AuditDbRpcs.assertEventRecorded,
      params: {
        AuditDbRpcParams.companyId: data.companyId,
        AuditDbRpcParams.module: data.module.value,
        AuditDbRpcParams.entityType: data.entityType.value,
        AuditDbRpcParams.entityId: data.entityId,
        AuditDbRpcParams.action: data.action.value,
        AuditDbRpcParams.auditEvent: data.description,
      },
    );
  }

  @override
  Future<List<AuditLogModel>> getEntityAuditLogs({
    required String companyId,
    required AuditModule module,
    required AuditEntityType entityType,
    required String entityId,
  }) async {
    final rows = await _client
        .from(AuditDbFields.tableName)
        .select()
        .eq(DbCommonFields.companyId, companyId)
        .eq(AuditDbFields.module, module.value)
        .eq(AuditDbFields.entityType, entityType.value)
        .eq(AuditDbFields.entityId, entityId)
        .order(DbCommonFields.createdAt, ascending: false);

    return rows
        .map((row) => AuditLogModel.fromMap(Map<String, dynamic>.from(row)))
        .toList();
  }
}
