import '../../domain/entities/audit_action.dart';
import '../../domain/entities/audit_entity_type.dart';
import '../../domain/entities/audit_log.dart';
import '../../domain/entities/audit_module.dart';
import '../../../../core/data/constants/db_common_fields.dart';
import '../constants/audit_db_fields.dart';

class AuditLogModel {
  final String id;
  final String companyId;
  final String? actorUserId;
  final String? actorRole;
  final String? actorDisplayName;
  final String? actorEmail;
  final String module;
  final String entityType;
  final String entityId;
  final String? entityDisplayName;
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
    this.actorDisplayName,
    this.actorEmail,
    required this.module,
    required this.entityType,
    required this.entityId,
    this.entityDisplayName,
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
      companyId: map[DbCommonFields.companyId] as String,
      actorUserId: map[AuditDbFields.actorUserId] as String?,
      actorRole: map[AuditDbFields.actorRole] as String?,
      actorDisplayName: map[AuditDbFields.actorDisplayName] as String?,
      actorEmail: map[AuditDbFields.actorEmail] as String?,
      module: map[AuditDbFields.module] as String,
      entityType: map[AuditDbFields.entityType] as String,
      entityId: map[AuditDbFields.entityId] as String,
      entityDisplayName: map[AuditDbFields.entityDisplayName] as String?,
      action: map[AuditDbFields.action] as String,
      description: map[AuditDbFields.description] as String,
      oldValues: _toMap(map[AuditDbFields.oldValues]),
      newValues: _toMap(map[AuditDbFields.newValues]),
      metadata: _toMap(map[AuditDbFields.metadata]),
      createdAt: DateTime.parse(map['created_at'].toString()),
    );
  }

  AuditLog toEntity() {
    return AuditLog(
      id: id,
      companyId: companyId,
      actorUserId: actorUserId,
      actorRole: actorRole,
      actorDisplayName: actorDisplayName,
      actorEmail: actorEmail,
      module: _moduleFromValue(module),
      entityType: _entityTypeFromValue(entityType),
      entityId: entityId,
      entityDisplayName: entityDisplayName,
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
