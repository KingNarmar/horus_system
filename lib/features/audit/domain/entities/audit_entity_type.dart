enum AuditEntityType { customer, driver, tractorHead, trailer, trip, expense, invoice, payment, companyUser, companySettings }

extension AuditEntityTypeX on AuditEntityType {
  String get value {
    return switch (this) {
      AuditEntityType.customer => 'customer',
      AuditEntityType.driver => 'driver',
      AuditEntityType.tractorHead => 'tractor_head',
      AuditEntityType.trailer => 'trailer',
      AuditEntityType.trip => 'trip',
      AuditEntityType.expense => 'expense',
      AuditEntityType.invoice => 'invoice',
      AuditEntityType.payment => 'payment',
      AuditEntityType.companyUser => 'company_user',
      AuditEntityType.companySettings => 'company_settings',
    };
  }
}
