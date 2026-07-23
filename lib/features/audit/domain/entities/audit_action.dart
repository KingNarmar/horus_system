enum AuditAction { created, updated, deactivated, reactivated, statusChanged }

extension AuditActionX on AuditAction {
  String get value {
    return switch (this) {
      AuditAction.created => 'created',
      AuditAction.updated => 'updated',
      AuditAction.deactivated => 'deactivated',
      AuditAction.reactivated => 'reactivated',
      AuditAction.statusChanged => 'status_changed',
    };
  }
}
