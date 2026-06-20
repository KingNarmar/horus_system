enum AuditModule {
  customers,
  drivers,
  fleet,
  routes,
  trips,
  expenses,
  invoices,
  payments,
  companyUsers,
  companySettings,
}

extension AuditModuleX on AuditModule {
  String get value {
    return switch (this) {
      AuditModule.customers => 'customers',
      AuditModule.drivers => 'drivers',
      AuditModule.fleet => 'fleet',
      AuditModule.routes => 'routes',
      AuditModule.trips => 'trips',
      AuditModule.expenses => 'expenses',
      AuditModule.invoices => 'invoices',
      AuditModule.payments => 'payments',
      AuditModule.companyUsers => 'company_users',
      AuditModule.companySettings => 'company_settings',
    };
  }
}
