import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/audit_entity_type.dart';
import '../../domain/entities/audit_log_write_data.dart';
import '../../domain/entities/audit_module.dart';
import '../mappers/audit_log_mapper.dart';
import '../models/audit_log_model.dart';
import '../../../../core/data/constants/db_common_fields.dart';
import '../constants/audit_db_fields.dart';
import '../../../../core/data/constants/user_profile_db_fields.dart';

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

  @override
  Future<void> createAuditLog({required AuditLogWriteData data}) async {
    final currentUser = _client.auth.currentUser;
    final currentUserId = currentUser?.id;
    final resolvedActorUserId =
        _normalizeOptional(data.actorUserId) ?? currentUserId;
    final resolvedActorEmail =
        _normalizeOptional(data.actorEmail) ??
        (resolvedActorUserId == currentUserId ? currentUser?.email : null);
    final resolvedActorDisplayName =
        _normalizeOptional(data.actorDisplayName) ??
        await _getActorDisplayName(resolvedActorUserId) ??
        resolvedActorEmail ??
        _normalizeOptional(data.actorRole);

    await _client
        .from(AuditDbFields.tableName)
        .insert(
          data.toInsertMap(
            resolvedActorUserId: resolvedActorUserId,
            resolvedActorDisplayName: resolvedActorDisplayName,
            resolvedActorEmail: resolvedActorEmail,
          ),
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

  Future<String?> _getActorDisplayName(String? actorUserId) async {
    final normalizedActorUserId = _normalizeOptional(actorUserId);
    if (normalizedActorUserId == null) return null;

    final rows = await _client
        .from(UserProfileDbFields.tableName)
        .select(UserProfileDbFields.fullName)
        .eq(DbCommonFields.id, normalizedActorUserId)
        .limit(1);

    if (rows.isEmpty) return null;
    final firstRow = Map<String, dynamic>.from(rows.first);
    return _normalizeOptional(
      firstRow[UserProfileDbFields.fullName] as String?,
    );
  }

  String? _normalizeOptional(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }
}
