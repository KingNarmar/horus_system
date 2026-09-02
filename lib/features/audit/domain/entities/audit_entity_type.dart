enum AuditEntityType {
  customer,
  driver,
  tractorHead,
  trailer,
  route,
  trip,
  expense,
  expenseType,
  invoice,
  payment,
  paymentMethod,
  companyUser,
  companySettings,
}

extension AuditEntityTypeX on AuditEntityType {
  String get value {
    return switch (this) {
      AuditEntityType.customer => 'customer',
      AuditEntityType.driver => 'driver',
      AuditEntityType.tractorHead => 'tractor_head',
      AuditEntityType.trailer => 'trailer',
      AuditEntityType.route => 'route',
      AuditEntityType.trip => 'trip',
      AuditEntityType.expense => 'expense',
      AuditEntityType.expenseType => 'expense_type',
      AuditEntityType.invoice => 'invoice',
      AuditEntityType.payment => 'payment',
      AuditEntityType.paymentMethod => 'payment_method',
      AuditEntityType.companyUser => 'company_user',
      AuditEntityType.companySettings => 'company_settings',
    };
  }
}
