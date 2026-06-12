import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/audit_log_write_data.dart';
import '../mappers/audit_log_mapper.dart';

abstract class AuditLogsRemoteDataSource {
  Future<void> createAuditLog({required AuditLogWriteData data});
}

class SupabaseAuditLogsRemoteDataSource implements AuditLogsRemoteDataSource {
  final SupabaseClient _client;

  const SupabaseAuditLogsRemoteDataSource(this._client);

  @override
  Future<void> createAuditLog({required AuditLogWriteData data}) async {
    final currentUserId = _client.auth.currentUser?.id;
    final resolvedActorUserId =
        _normalizeOptional(data.actorUserId) ?? currentUserId;

    await _client
        .from('audit_logs')
        .insert(data.toInsertMap(resolvedActorUserId: resolvedActorUserId));
  }

  String? _normalizeOptional(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }
}
