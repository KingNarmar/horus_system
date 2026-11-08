import 'audit_action.dart';
import 'audit_entity_type.dart';
import 'audit_module.dart';

class AuditLog {
  final String id;
  final String companyId;
  final String? actorUserId;
  final String? actorRole;
  final String? actorDisplayName;
  final String? actorEmail;
  final AuditModule module;
  final AuditEntityType entityType;

  // Preserve exact event identity when a future/legacy semantic key is unknown.
  // These values are diagnostic data, not user-facing display labels.
  final String? rawModule;
  final String? rawEntityType;
  final String entityId;
  final String? entityDisplayName;
  final AuditAction action;
  final String? rawAction;
  final String description;
  final Map<String, Object?>? oldValues;
  final Map<String, Object?>? newValues;
  final Map<String, Object?>? metadata;
  final DateTime createdAt;

  const AuditLog({
    required this.id,
    required this.companyId,
    this.actorUserId,
    this.actorRole,
    this.actorDisplayName,
    this.actorEmail,
    required this.module,
    required this.entityType,
    this.rawModule,
    this.rawEntityType,
    required this.entityId,
    this.entityDisplayName,
    required this.action,
    this.rawAction,
    required this.description,
    this.oldValues,
    this.newValues,
    this.metadata,
    required this.createdAt,
  });
}
