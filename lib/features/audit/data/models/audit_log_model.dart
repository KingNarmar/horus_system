import '../../domain/entities/audit_action.dart';
import '../../domain/entities/audit_entity_type.dart';
import '../../domain/entities/audit_log.dart';
import '../../domain/entities/audit_module.dart';

class AuditLogModel {
  final String id;
  final String companyId;
  final String? actorUserId;
  final String? actorRole;
  final String module;
  final String entityType;
  final String entityId;
  final String action;
  final String description;
  final Map<String, dynamic>? oldValues;
  final Map<String, dynamic>? newValues;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  const AuditLogModel({
    required this.id,
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
    required this.createdAt,
  });

  factory AuditLogModel.fromMap(Map<String, dynamic> map) {
    return AuditLogModel(
      id: map['id'] as String,
      companyId: map['company_id'] as String,
      actorUserId: map['actor_user_id'] as String?,
      actorRole: map['actor_role'] as String?,
      module: map['module'] as String,
      entityType: map['entity_type'] as String,
      entityId: map['entity_id'] as String,
      action: map['action'] as String,
      description: map['description'] as String,
      oldValues: _toMap(map['old_values']),
      newValues: _toMap(map['new_values']),
      metadata: _toMap(map['metadata']),
      createdAt: DateTime.parse(map['created_at'].toString()),
    );
  }

  AuditLog toEntity() {
    return AuditLog(
      id: id,
      companyId: companyId,
      actorUserId: actorUserId,
      actorRole: actorRole,
      module: _moduleFromValue(module),
      entityType: _entityTypeFromValue(entityType),
      entityId: entityId,
      action: _actionFromValue(action),
      description: description,
      oldValues: oldValues,
      newValues: newValues,
      metadata: metadata,
      createdAt: createdAt,
    );
  }

  static Map<String, dynamic>? _toMap(Object? value) {
    if (value == null) return null;
    return Map<String, dynamic>.from(value as Map);
  }

  static AuditModule _moduleFromValue(String value) {
    return AuditModule.values.firstWhere(
      (item) => item.value == value,
      orElse: () => AuditModule.customers,
    );
  }

  static AuditEntityType _entityTypeFromValue(String value) {
    return AuditEntityType.values.firstWhere(
      (item) => item.value == value,
      orElse: () => AuditEntityType.customer,
    );
  }

  static AuditAction _actionFromValue(String value) {
    return AuditAction.values.firstWhere(
      (item) => item.value == value,
      orElse: () => AuditAction.updated,
    );
  }
}
