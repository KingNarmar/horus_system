abstract final class AuditDbFields {
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

abstract final class AuditDbRpcs {
  static const assertEventRecorded = 'assert_audit_event_recorded';
}

abstract final class AuditDbRpcParams {
  static const companyId = 'p_company_id';
  static const module = 'p_module';
  static const entityType = 'p_entity_type';
  static const entityId = 'p_entity_id';
  static const action = 'p_action';
  static const auditEvent = 'p_audit_event';
}
