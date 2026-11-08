enum AuditAction {
  created,
  updated,
  deactivated,
  reactivated,
  statusChanged,
  accepted,
  cancelled,
  issued,
  paymentStatusChanged,
  registered,
  resent,
  revoked,
  sent,
  voided,
  unknown,
}

extension AuditActionX on AuditAction {
  String get value {
    return switch (this) {
      AuditAction.created => 'created',
      AuditAction.updated => 'updated',
      AuditAction.deactivated => 'deactivated',
      AuditAction.reactivated => 'reactivated',
      AuditAction.statusChanged => 'status_changed',
      AuditAction.accepted => 'accepted',
      AuditAction.cancelled => 'cancelled',
      AuditAction.issued => 'issued',
      AuditAction.paymentStatusChanged => 'payment_status_changed',
      AuditAction.registered => 'registered',
      AuditAction.resent => 'resent',
      AuditAction.revoked => 'revoked',
      AuditAction.sent => 'sent',
      AuditAction.voided => 'voided',
      AuditAction.unknown => 'unknown',
    };
  }
}
