enum AuditEntityType {
  customer,
  driver,
  driverCompensationRevision,
  tractorHead,
  trailer,
  route,
  trip,
  expense,
  expenseType,
  expenseLedgerEntry,
  invoice,
  payment,
  paymentMethod,
  company,
  companyInvitation,
  companyUser,
  companySettings,
  unknown,
}

extension AuditEntityTypeX on AuditEntityType {
  String get value {
    return switch (this) {
      AuditEntityType.customer => 'customer',
      AuditEntityType.driver => 'driver',
      AuditEntityType.driverCompensationRevision => 'driver_compensation_revision',
      AuditEntityType.tractorHead => 'tractor_head',
      AuditEntityType.trailer => 'trailer',
      AuditEntityType.route => 'route',
      AuditEntityType.trip => 'trip',
      AuditEntityType.expense => 'expense',
      AuditEntityType.expenseType => 'expense_type',
      AuditEntityType.expenseLedgerEntry => 'expense_ledger_entry',
      AuditEntityType.invoice => 'invoice',
      AuditEntityType.payment => 'payment',
      AuditEntityType.paymentMethod => 'payment_method',
      AuditEntityType.company => 'company',
      AuditEntityType.companyInvitation => 'company_invitation',
      AuditEntityType.companyUser => 'company_user',
      AuditEntityType.companySettings => 'company_settings',
      AuditEntityType.unknown => 'unknown',
    };
  }
}
