import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/data/constants/db_common_fields.dart';
import '../../domain/entities/audit_entity_type.dart';
import '../../domain/entities/audit_module.dart';
import '../constants/audit_db_fields.dart';
import '../models/audit_log_model.dart';

abstract class AuditLogsRemoteDataSource {
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
