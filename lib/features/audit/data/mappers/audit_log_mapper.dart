import '../../domain/entities/audit_action.dart';
import '../../domain/entities/audit_entity_type.dart';
import '../../domain/entities/audit_log_write_data.dart';
import '../../domain/entities/audit_module.dart';

extension AuditLogWriteDataMapper on AuditLogWriteData {
  Map<String, dynamic> toInsertMap({String? resolvedActorUserId}) {
    return {
      'company_id': companyId,
      'actor_user_id': resolvedActorUserId ?? actorUserId,
      'actor_role': actorRole,
      'module': module.value,
      'entity_type': entityType.value,
      'entity_id': entityId,
      'action': action.value,
      'description': description,
      'old_values': oldValues,
      'new_values': newValues,
      'metadata': metadata,
    };
  }
}
