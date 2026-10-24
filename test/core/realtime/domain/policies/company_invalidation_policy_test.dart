import 'package:horus_system/core/realtime/domain/entities/company_data_change.dart';
import 'package:horus_system/core/realtime/domain/entities/company_invalidation_resource.dart';
import 'package:horus_system/core/realtime/domain/policies/company_invalidation_policy.dart';
import 'package:test/test.dart';

void main() {
  test('Customers affects its list and dependent read projections', () {
    final affected = CompanyInvalidationPolicy.affectedBy(
      CompanyDataResource.customers,
    );

    expect(affected, contains(CompanyInvalidationResource.customers));
    expect(affected, contains(CompanyInvalidationResource.tripFormLookups));
    expect(affected, contains(CompanyInvalidationResource.customerStatements));
    expect(affected, isNot(contains(CompanyInvalidationResource.payments)));
  });

  test('Trip mutations include status history without Trip Documents', () {
    final affected = CompanyInvalidationPolicy.affectedBy(
      CompanyDataResource.trips,
    );
    expect(affected, contains(CompanyInvalidationResource.trips));
    expect(affected, contains(CompanyInvalidationResource.tripStatusHistory));
    expect(
      affected,
      isNot(contains(CompanyInvalidationResource.tripDocuments)),
    );
  });

  test('Fleet license documents only invalidate document projections', () {
    final affected = CompanyInvalidationPolicy.affectedBy(
      CompanyDataResource.fleetLicenseDocuments,
    );

    expect(affected, {CompanyInvalidationResource.fleetLicenseDocuments});
  });

  test('Company Expenses invalidation stays out of Trip financial refresh', () {
    final affected = CompanyInvalidationPolicy.affectedBy(
      CompanyDataResource.companyExpenses,
    );
    expect(affected, contains(CompanyInvalidationResource.companyExpenses));
    expect(
      affected,
      isNot(contains(CompanyInvalidationResource.tripFinancials)),
    );
    expect(affected, isNot(contains(CompanyInvalidationResource.trips)));
  });

  test('ledger invalidation does not reload Trips for unrelated costs', () {
    final affected = CompanyInvalidationPolicy.affectedBy(
      CompanyDataResource.expenseLedger,
    );

    expect(affected, contains(CompanyInvalidationResource.expenseLedger));
    expect(affected, contains(CompanyInvalidationResource.driverBalances));
    expect(affected, contains(CompanyInvalidationResource.settlementSources));
    expect(affected, contains(CompanyInvalidationResource.dashboard));
    expect(affected, contains(CompanyInvalidationResource.tripNetProfitReport));
    expect(affected, isNot(contains(CompanyInvalidationResource.trips)));
    expect(
      affected,
      isNot(contains(CompanyInvalidationResource.tripFinancials)),
    );
  });

  test('trip-attributed Ledger mutation invalidates dependent Trip views', () {
    final affected = CompanyInvalidationPolicy.affectedBy(
      CompanyDataResource.tripExpenses,
    );

    expect(affected, contains(CompanyInvalidationResource.tripFinancials));
    expect(affected, contains(CompanyInvalidationResource.trips));
    expect(
      affected,
      isNot(contains(CompanyInvalidationResource.driverBalances)),
    );
    expect(
      affected,
      isNot(contains(CompanyInvalidationResource.settlementSources)),
    );
    expect(affected, isNot(contains(CompanyInvalidationResource.invoices)));
  });

  test('settlement mutations invalidate balances, not unrelated reports', () {
    final affected = CompanyInvalidationPolicy.affectedBy(
      CompanyDataResource.driverSettlements,
    );
    expect(affected, contains(CompanyInvalidationResource.driverSettlements));
    expect(affected, contains(CompanyInvalidationResource.driverBalances));
    expect(affected, isNot(contains(CompanyInvalidationResource.invoices)));
    expect(affected, isNot(contains(CompanyInvalidationResource.dashboard)));
  });

  test('payments affect statements and open invoices, not trip lookups', () {
    final affected = CompanyInvalidationPolicy.affectedBy(
      CompanyDataResource.payments,
    );

    expect(affected, contains(CompanyInvalidationResource.invoices));
    expect(affected, contains(CompanyInvalidationResource.customerStatements));
    expect(affected, contains(CompanyInvalidationResource.openInvoicesReport));
    expect(
      affected,
      isNot(contains(CompanyInvalidationResource.tripFormLookups)),
    );
  });

  test('operational lookups change only for their relevant sources', () {
    final affected = CompanyInvalidationPolicy.affectedBy(
      CompanyDataResource.routes,
    );

    expect(affected, contains(CompanyInvalidationResource.tripFormLookups));
    expect(affected, contains(CompanyInvalidationResource.trips));
    expect(affected, contains(CompanyInvalidationResource.routes));
    expect(affected, contains(CompanyInvalidationResource.operationalReports));
    expect(affected, isNot(contains(CompanyInvalidationResource.payments)));
  });

  test('each declared source has a focused, immutable resource set', () {
    for (final source in CompanyDataResource.values) {
      final affected = CompanyInvalidationPolicy.affectedBy(source);
      expect(affected, isNotEmpty, reason: source.name);
      expect(
        () => affected.add(CompanyInvalidationResource.payments),
        throwsUnsupportedError,
        reason: source.name,
      );
    }
  });
}
