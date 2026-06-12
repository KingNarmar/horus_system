import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/audit_entity_type.dart';
import '../../domain/entities/audit_log_write_data.dart';
import '../../domain/entities/audit_module.dart';
import '../mappers/audit_log_mapper.dart';
import '../models/audit_log_model.dart';

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
    final resolvedActorEmail = _normalizeOptional(data.actorEmail) ??
        (resolvedActorUserId == currentUserId ? currentUser?.email : null);
    final resolvedActorDisplayName = _normalizeOptional(data.actorDisplayName) ??
        await _getActorDisplayName(resolvedActorUserId) ??
        resolvedActorEmail ??
        _normalizeOptional(data.actorRole);

    await _client.from('audit_logs').insert(
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
        .from('audit_logs')
        .select()
        .eq('company_id', companyId)
        .eq('module', module.value)
        .eq('entity_type', entityType.value)
        .eq('entity_id', entityId)
        .order('created_at', ascending: false);

    return rows
        .map((row) => AuditLogModel.fromMap(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<String?> _getActorDisplayName(String? actorUserId) async {
    final normalizedActorUserId = _normalizeOptional(actorUserId);
    if (normalizedActorUserId == null) return null;

    final rows = await _client
        .from('user_profiles')
        .select('full_name')
        .eq('id', normalizedActorUserId)
        .limit(1);

    if (rows.isEmpty) return null;
    final firstRow = Map<String, dynamic>.from(rows.first);
    return _normalizeOptional(firstRow['full_name'] as String?);
  }

  String? _normalizeOptional(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }
}
