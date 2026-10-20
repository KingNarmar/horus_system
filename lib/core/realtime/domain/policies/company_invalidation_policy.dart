import '../entities/company_data_change.dart';
import '../entities/company_invalidation_resource.dart';

/// Maps server-owned mutation sources to authoritative read projections.
///
/// This describes dependencies; it does not enable a Broadcast source.
/// Customers, Drivers and Fleet Assets sources are connected independently.
/// Other sources require separate server authorization and mutation review.
abstract final class CompanyInvalidationPolicy {
  static const Map<CompanyDataResource, Set<CompanyInvalidationResource>>
  _dependencies = {
    CompanyDataResource.customers: {
      CompanyInvalidationResource.customers,
      CompanyInvalidationResource.tripFormLookups,
      CompanyInvalidationResource.customerStatements,
      CompanyInvalidationResource.operationalReports,
      CompanyInvalidationResource.tripExpensesReport,
      CompanyInvalidationResource.tripNetProfitReport,
    },
    CompanyDataResource.drivers: {
      CompanyInvalidationResource.drivers,
      CompanyInvalidationResource.tripFormLookups,
      CompanyInvalidationResource.companyExpenseLookups,
      CompanyInvalidationResource.driverSettlementDriverOptions,
      CompanyInvalidationResource.operationalReports,
      CompanyInvalidationResource.tripNetProfitReport,
    },
    CompanyDataResource.fleet: {
      CompanyInvalidationResource.fleet,
      CompanyInvalidationResource.tripFormLookups,
      CompanyInvalidationResource.companyExpenseLookups,
      CompanyInvalidationResource.operationalReports,
      CompanyInvalidationResource.tripNetProfitReport,
      CompanyInvalidationResource.dashboard,
    },
    CompanyDataResource.routes: {
      CompanyInvalidationResource.routes,
      CompanyInvalidationResource.trips,
      CompanyInvalidationResource.tripFormLookups,
      CompanyInvalidationResource.operationalReports,
      CompanyInvalidationResource.tripExpensesReport,
      CompanyInvalidationResource.tripNetProfitReport,
    },
    CompanyDataResource.trips: {
      CompanyInvalidationResource.trips,
      CompanyInvalidationResource.tripStatusHistory,
      CompanyInvalidationResource.companyExpenseLookups,
      CompanyInvalidationResource.driverFinanceTripOptions,
      CompanyInvalidationResource.driverBalances,
      CompanyInvalidationResource.settlementSources,
      CompanyInvalidationResource.billableTrips,
      CompanyInvalidationResource.dashboard,
      CompanyInvalidationResource.operationalReports,
      CompanyInvalidationResource.tripExpensesReport,
      CompanyInvalidationResource.tripNetProfitReport,
    },
    CompanyDataResource.tripStatusHistory: {
      CompanyInvalidationResource.tripStatusHistory,
      CompanyInvalidationResource.trips,
    },
    CompanyDataResource.tripDocuments: {
      CompanyInvalidationResource.tripDocuments,
    },
    CompanyDataResource.fleetLicenseDocuments: {
      CompanyInvalidationResource.fleetLicenseDocuments,
    },
    CompanyDataResource.expenseLedger: {
      CompanyInvalidationResource.expenseLedger,
      CompanyInvalidationResource.dashboard,
      CompanyInvalidationResource.tripExpensesReport,
      CompanyInvalidationResource.tripNetProfitReport,
    },
    CompanyDataResource.tripExpenses: {
      CompanyInvalidationResource.tripFinancials,
      CompanyInvalidationResource.trips,
      CompanyInvalidationResource.driverBalances,
      CompanyInvalidationResource.settlementSources,
    },
    CompanyDataResource.companyExpenses: {
      CompanyInvalidationResource.companyExpenses,
      CompanyInvalidationResource.dashboard,
    },
    CompanyDataResource.expenseTypes: {
      CompanyInvalidationResource.expenseTypes,
      CompanyInvalidationResource.expenseLedger,
      CompanyInvalidationResource.tripExpensesReport,
    },
    CompanyDataResource.driverFinance: {
      CompanyInvalidationResource.driverFinance,
      CompanyInvalidationResource.driverBalances,
      CompanyInvalidationResource.settlementSources,
    },
    CompanyDataResource.driverSettlements: {
      CompanyInvalidationResource.driverSettlements,
      CompanyInvalidationResource.driverBalances,
    },
    CompanyDataResource.invoices: {
      CompanyInvalidationResource.invoices,
      CompanyInvalidationResource.billableTrips,
      CompanyInvalidationResource.customerStatements,
      CompanyInvalidationResource.openInvoicesReport,
      CompanyInvalidationResource.dashboard,
    },
    CompanyDataResource.payments: {
      CompanyInvalidationResource.payments,
      CompanyInvalidationResource.invoices,
      CompanyInvalidationResource.customerStatements,
      CompanyInvalidationResource.openInvoicesReport,
      CompanyInvalidationResource.dashboard,
    },
    CompanyDataResource.paymentMethods: {
      CompanyInvalidationResource.paymentMethods,
      CompanyInvalidationResource.paymentFormLookups,
    },
    CompanyDataResource.financialSettings: {
      CompanyInvalidationResource.financialSettings,
      CompanyInvalidationResource.dashboard,
      CompanyInvalidationResource.tripNetProfitReport,
      CompanyInvalidationResource.tripExpensesReport,
      CompanyInvalidationResource.openInvoicesReport,
      CompanyInvalidationResource.customerStatements,
    },
    CompanyDataResource.invoiceSettings: {
      CompanyInvalidationResource.invoiceSettings,
    },
    CompanyDataResource.companyTimezone: {
      CompanyInvalidationResource.companyTimezone,
      CompanyInvalidationResource.dashboard,
    },
  };

  static Set<CompanyInvalidationResource> affectedBy(
    CompanyDataResource source,
  ) => _dependencies[source] ?? const <CompanyInvalidationResource>{};
}
