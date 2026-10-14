/// Server mutation origins. Enabling an origin requires a reviewed
/// server-owned Broadcast and a resource-specific subscription.
/// Additional sources require separately reviewed server-side authorization.
enum CompanyDataResource {
  customers,
  drivers,
  fleet,
  routes,
  trips,
  tripStatusHistory,
  tripDocuments,
  fleetLicenseDocuments,
  expenseLedger,
  companyExpenses,
  expenseTypes,
  driverFinance,
  driverSettlements,
  invoices,
  payments,
  paymentMethods,
  financialSettings,
  invoiceSettings,
  companyTimezone,
}

final class CompanyDataChange {
  final String companyId;
  final CompanyDataResource resource;

  const CompanyDataChange({required this.companyId, required this.resource});
}
