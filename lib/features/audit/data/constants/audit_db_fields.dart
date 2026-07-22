abstract class AuditDbFields {
  static const tableName = 'audit_logs';

  static const actorUserId = 'actor_user_id';
  static const actorRole = 'actor_role';
  static const actorDisplayName = 'actor_display_name';
  static const actorEmail = 'actor_email';

  static const module = 'module';
  static const entityType = 'entity_type';
  static const entityId = 'entity_id';
  static const entityDisplayName = 'entity_display_name';

  static const action = 'action';
  static const description = 'description';
  static const oldValues = 'old_values';
  static const newValues = 'new_values';
  static const metadata = 'metadata';
}
