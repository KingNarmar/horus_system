import 'package:horus_system/features/audit/domain/entities/audit_action.dart';
import 'package:horus_system/features/audit/domain/entities/audit_entity_type.dart';
import 'package:horus_system/features/audit/domain/entities/audit_module.dart';

import '../../domain/entities/audit_log_write_data.dart';
import '../../../../core/data/constants/db_common_fields.dart';
import '../constants/audit_db_fields.dart';

extension AuditLogWriteDataMapper on AuditLogWriteData {
  Map<String, dynamic> toInsertMap({
    String? resolvedActorUserId,
    String? resolvedActorDisplayName,
    String? resolvedActorEmail,
  }) {
    return {
      DbCommonFields.companyId: companyId,
      AuditDbFields.actorUserId: resolvedActorUserId ?? actorUserId,
      AuditDbFields.actorRole: actorRole,
      AuditDbFields.actorDisplayName: resolvedActorDisplayName ?? actorDisplayName,
      AuditDbFields.actorEmail: resolvedActorEmail ?? actorEmail,
      AuditDbFields.module: module.value,
      AuditDbFields.entityType: entityType.value,
      AuditDbFields.entityId: entityId,
      AuditDbFields.entityDisplayName: entityDisplayName,
      AuditDbFields.action: action.value,
      AuditDbFields.description: description,
      AuditDbFields.oldValues: oldValues,
      AuditDbFields.newValues: newValues,
      AuditDbFields.metadata: metadata,
    };
  }
}
