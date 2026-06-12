import 'audit_action.dart';
import 'audit_entity_type.dart';
import 'audit_module.dart';

class AuditLogWriteData {
  final String companyId;
  final String? actorUserId;
  final String? actorRole;
  final AuditModule module;
  final AuditEntityType entityType;
  final String entityId;
  final AuditAction action;
  final String description;
  final Map<String, Object?>? oldValues;
  final Map<String, Object?>? newValues;
  final Map<String, Object?>? metadata;

  const AuditLogWriteData({
    required this.companyId,
    this.actorUserId,
    this.actorRole,
    required this.module,
    required this.entityType,
    required this.entityId,
    required this.action,
    required this.description,
    this.oldValues,
    this.newValues,
    this.metadata,
  });
}
