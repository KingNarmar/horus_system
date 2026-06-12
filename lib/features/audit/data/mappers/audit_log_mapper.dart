import '../../domain/entities/audit_log_write_data.dart';

extension AuditLogWriteDataMapper on AuditLogWriteData {
  Map<String, dynamic> toInsertMap({
    String? resolvedActorUserId,
    String? resolvedActorDisplayName,
    String? resolvedActorEmail,
  }) {
    return {
      'company_id': companyId,
      'actor_user_id': resolvedActorUserId ?? actorUserId,
      'actor_role': actorRole,
      'actor_display_name': resolvedActorDisplayName ?? actorDisplayName,
      'actor_email': resolvedActorEmail ?? actorEmail,
      'module': module.value,
      'entity_type': entityType.value,
      'entity_id': entityId,
      'entity_display_name': entityDisplayName,
      'action': action.value,
      'description': description,
      'old_values': oldValues,
      'new_values': newValues,
      'metadata': metadata,
    };
  }
}
