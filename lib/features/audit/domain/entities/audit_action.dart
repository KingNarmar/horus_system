enum AuditAction {
  created,
  updated,
  deactivated,
  reactivated,
  statusChanged,
  driverFinanceAdded,
}

extension AuditActionX on AuditAction {
  String get value {
    return switch (this) {
      AuditAction.created => 'created',
      AuditAction.updated => 'updated',
      AuditAction.deactivated => 'deactivated',
      AuditAction.reactivated => 'reactivated',
      AuditAction.statusChanged => 'status_changed',
      AuditAction.driverFinanceAdded => 'driver_finance_added',
    };
  }
}
