import 'package:horus_system/core/domain/value_objects/currency_code.dart';
import 'package:horus_system/core/domain/value_objects/money.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/entities/current_company_context.dart';
import 'package:horus_system/features/expenses/domain/entities/trip_expense_paid_by.dart';
import 'package:horus_system/features/invoices/domain/entities/invoice_status.dart';
import 'package:horus_system/features/reports/domain/entities/open_invoices_report.dart';
import 'package:horus_system/features/reports/domain/entities/operational_trip_report.dart';
import 'package:horus_system/features/reports/domain/entities/report_date_range.dart';
import 'package:horus_system/features/reports/domain/entities/report_source_metadata.dart';
import 'package:horus_system/features/reports/domain/entities/trip_expenses_report.dart';
import 'package:horus_system/features/reports/domain/entities/trip_net_profit_report.dart';
import 'package:horus_system/features/reports/domain/failures/reports_failure_codes.dart';
import 'package:horus_system/features/reports/domain/repositories/reports_repository.dart';
import 'package:horus_system/features/reports/domain/usecases/get_open_invoices_report_usecase.dart';
import 'package:horus_system/features/reports/domain/usecases/get_operational_report_usecase.dart';
import 'package:horus_system/features/reports/domain/usecases/get_trip_expenses_report_usecase.dart';
import 'package:horus_system/features/reports/domain/usecases/get_trip_net_profit_report_usecase.dart';
import 'package:horus_system/features/reports/domain/usecases/report_params.dart';
import 'package:horus_system/features/trips/domain/entities/trip_status.dart';
import 'package:test/test.dart';

void main() {
  test('operational report groups unassigned drivers and keeps cancelled trips', () async {
    final repository = _FakeReportsRepository(
      operational: (companyId, from, to) => OperationalTripReportSource(
        metadata: _metadata(companyId, from, to),
        rows: [
          _operationalRow(id: 'trip-1', driverId: 'driver-1', driverName: 'Ali'),
          _operationalRow(
            id: 'trip-2',
            driverId: null,
            driverName: null,
            status: TripStatus.cancelled,
          ),
        ],
      ),
    );
    final useCase = GetOperationalReportUseCase(repository: repository);

    final result = await useCase(
      OperationalReportParams(
        currentCompanyContext: _context(CompanyRole.viewer),
        dimension: OperationalReportDimension.driver,
        dateRange: const ReportDateRange(),
      ),
    );

    final report = result.dataOrNull;
    expect(report, isNotNull);
    expect(report!.totalTrips, 2);
    expect(report.groups, hasLength(2));
    expect(report.groups.last.entityId, isNull);
    expect(report.groups.last.rows.single.status, TripStatus.cancelled);
  });

  test('driver is denied operational reports before repository access', () async {
    final repository = _FakeReportsRepository();
    final useCase = GetOperationalReportUseCase(repository: repository);

    final result = await useCase(
      OperationalReportParams(
        currentCompanyContext: _context(CompanyRole.driver),
        dimension: OperationalReportDimension.day,
        dateRange: const ReportDateRange(),
      ),
    );

    expect(
      result.failureOrNull?.code,
      ReportsFailureCodes.permissionOperationalView,
    );
    expect(repository.operationalCalls, 0);
  });

  test('invalid inclusive date range fails before repository access', () async {
    final repository = _FakeReportsRepository();
    final useCase = GetOperationalReportUseCase(repository: repository);

    final result = await useCase(
      OperationalReportParams(
        currentCompanyContext: _context(CompanyRole.owner),
        dimension: OperationalReportDimension.day,
        dateRange: ReportDateRange(
          fromDate: DateTime(2026, 6, 21),
          toDate: DateTime(2026, 6, 20),
        ),
      ),
    );

    expect(result.failureOrNull?.code, ReportsFailureCodes.validationDateRange);
    expect(repository.operationalCalls, 0);
  });

  test('trip expenses total is composed in Domain', () async {
    final currency = _currency;
    final repository = _FakeReportsRepository(
      expenses: (companyId, from, to) => TripExpensesReportSource(
        metadata: _metadata(companyId, from, to),
        precisionLossCount: 0,
        negativeAmountCount: 0,
        rows: [
          _expenseRow('expense-1', Money(minorUnits: 1250, currency: currency)),
          _expenseRow('expense-2', Money(minorUnits: 2750, currency: currency)),
        ],
      ),
    );
    final useCase = GetTripExpensesReportUseCase(repository);

    final result = await useCase(
      ReportParams(
        currentCompanyContext: _context(CompanyRole.accountant),
        dateRange: const ReportDateRange(),
      ),
    );

    expect(result.dataOrNull?.totalExpenses.minorUnits, 4000);
  });

  test('trip net profit uses all authoritative linked expenses from source', () async {
    final currency = _currency;
    final repository = _FakeReportsRepository(
      netProfit: (companyId, from, to) => TripNetProfitReportSource(
        metadata: _metadata(companyId, from, to),
        freightPrecisionLossCount: 0,
        negativeFreightCount: 0,
        expensePrecisionLossCount: 0,
        negativeExpenseCount: 0,
        trips: [
          _profitTrip(
            id: 'trip-1',
            freight: Money(minorUnits: 500000, currency: currency),
          ),
        ],
        expenses: [
          TripNetProfitSourceExpense(
            expenseId: 'expense-late',
            tripId: 'trip-1',
            amount: Money(minorUnits: 20000, currency: currency),
          ),
        ],
      ),
    );
    final useCase = GetTripNetProfitReportUseCase(repository: repository);

    final result = await useCase(
      ReportParams(
        currentCompanyContext: _context(CompanyRole.owner),
        dateRange: ReportDateRange(
          fromDate: DateTime(2026, 6, 26),
          toDate: DateTime(2026, 6, 26),
        ),
      ),
    );

    final report = result.dataOrNull;
    expect(report?.totalFreight.minorUnits, 500000);
    expect(report?.totalExpenses.minorUnits, 20000);
    expect(report?.totalNetProfit.minorUnits, 480000);
    expect(report?.rows.single.netProfit.minorUnits, 480000);
  });

  test('open invoices validates paid rows but excludes them from final report', () async {
    final currency = _currency;
    final repository = _FakeReportsRepository(
      openInvoices: (companyId, from, to) => OpenInvoicesReportSource(
        metadata: _metadata(companyId, from, to),
        invoiceCurrencyMismatchCount: 0,
        paymentCurrencyMismatchCount: 0,
        invalidInvoiceAmountCount: 0,
        invalidPaymentAmountCount: 0,
        missingIssueDateCount: 0,
        invoices: [
          _invoice('issued', InvoiceStatus.issued, 100000),
          _invoice('partial', InvoiceStatus.partiallyPaid, 120000),
          _invoice('paid', InvoiceStatus.paid, 80000),
        ],
        payments: [
          _payment('pay-partial', 'partial', 40000, currency),
          _payment('pay-paid', 'paid', 80000, currency),
        ],
      ),
    );
    final useCase = GetOpenInvoicesReportUseCase(repository: repository);

    final result = await useCase(
      ReportParams(
        currentCompanyContext: _context(CompanyRole.operations),
        dateRange: const ReportDateRange(),
      ),
    );

    final report = result.dataOrNull;
    expect(report, isNotNull);
    expect(report!.rows.map((row) => row.invoice.invoiceId), ['issued', 'partial']);
    expect(report.rows.last.remaining.minorUnits, 80000);
    expect(report.totalOutstanding.minorUnits, 180000);
  });
}

CurrencyCode get _currency => CurrencyCode.tryParse('AED')!;

CurrentCompanyContext _context(CompanyRole role) {
  return CurrentCompanyContext(
    company: const Company(
      id: 'company-1',
      name: 'Company',
      baseCurrencyCode: 'AED',
      baseCurrencyFractionDigits: 2,
      businessTimezone: 'Asia/Dubai',
    ),
    role: role,
  );
}

ReportSourceMetadata _metadata(String companyId, DateTime? from, DateTime? to) {
  return ReportSourceMetadata(
    companyId: companyId,
    currency: _currency,
    baseCurrencyFractionDigits: 2,
    businessTimezone: 'Asia/Dubai',
    businessDate: DateTime(2026, 8, 13),
    fromDate: from,
    toDate: to,
  );
}

OperationalTripReportRow _operationalRow({
  required String id,
  required String? driverId,
  required String? driverName,
  TripStatus status = TripStatus.delivered,
}) {
  return OperationalTripReportRow(
    tripId: id,
    tripNumber: id,
    operationalDate: DateTime(2026, 6, 20),
    status: status,
    customerId: 'customer-1',
    customerName: 'Customer',
    driverId: driverId,
    driverName: driverName,
    tractorHeadId: 'tractor-1',
    tractorHeadPlateNumber: 'T-1',
    trailerId: 'trailer-1',
    trailerPlateNumber: 'R-1',
    routeId: 'route-1',
    loadingLocation: 'Dubai',
    unloadingLocation: 'Abu Dhabi',
    loadingOrderNumber: null,
    waybillNumber: null,
    cargoType: null,
    quantityTons: null,
  );
}

TripExpenseReportRow _expenseRow(String id, Money amount) {
  return TripExpenseReportRow(
    expenseId: id,
    expenseDate: DateTime(2026, 6, 26),
    tripId: 'trip-1',
    tripNumber: 'TR-1',
    tripDate: DateTime(2026, 6, 26),
    customerId: 'customer-1',
    customerName: 'Customer',
    loadingLocation: 'Dubai',
    unloadingLocation: 'Abu Dhabi',
    loadingOrderNumber: null,
    waybillNumber: null,
    expenseTypeId: null,
    expenseName: 'Fuel',
    paidBy: TripExpensePaidBy.company,
    amount: amount,
  );
}

TripNetProfitSourceTrip _profitTrip({required String id, required Money freight}) {
  return TripNetProfitSourceTrip(
    tripId: id,
    tripNumber: 'TR-1',
    operationalDate: DateTime(2026, 6, 26),
    status: TripStatus.delivered,
    customerId: 'customer-1',
    customerName: 'Customer',
    driverId: null,
    driverName: null,
    tractorHeadId: null,
    tractorHeadPlateNumber: null,
    trailerId: null,
    trailerPlateNumber: null,
    loadingLocation: 'Dubai',
    unloadingLocation: 'Abu Dhabi',
    loadingOrderNumber: null,
    waybillNumber: null,
    freight: freight,
  );
}

OpenInvoiceSourceInvoice _invoice(String id, InvoiceStatus status, int total) {
  return OpenInvoiceSourceInvoice(
    invoiceId: id,
    invoiceNumber: 'INV-$id',
    customerId: 'customer-1',
    customerName: 'Customer',
    status: status,
    total: Money(minorUnits: total, currency: _currency),
    issueDate: DateTime(2026, 7, 1),
    dueDate: DateTime(2026, 7, 31),
    issuedAt: DateTime(2026, 7, 1, 9),
  );
}

OpenInvoiceSourcePayment _payment(
  String id,
  String invoiceId,
  int amount,
  CurrencyCode currency,
) {
  return OpenInvoiceSourcePayment(
    paymentId: id,
    invoiceId: invoiceId,
    amount: Money(minorUnits: amount, currency: currency),
    paymentDate: DateTime(2026, 7, 10),
    createdAt: DateTime(2026, 7, 10, 10),
  );
}

final class _FakeReportsRepository implements ReportsRepository {
  final OperationalTripReportSource Function(String, DateTime?, DateTime?)? operational;
  final TripExpensesReportSource Function(String, DateTime?, DateTime?)? expenses;
  final TripNetProfitReportSource Function(String, DateTime?, DateTime?)? netProfit;
  final OpenInvoicesReportSource Function(String, DateTime?, DateTime?)? openInvoices;
  int operationalCalls = 0;

  _FakeReportsRepository({
    this.operational,
    this.expenses,
    this.netProfit,
    this.openInvoices,
  });

  @override
  Future<Result<OperationalTripReportSource>> getOperationalTripSource({
    required String companyId,
    required DateTime? fromDate,
    required DateTime? toDate,
  }) async {
    operationalCalls++;
    final builder = operational;
    if (builder == null) throw StateError('Unexpected operational source call.');
    return Success(builder(companyId, fromDate, toDate));
  }

  @override
  Future<Result<TripExpensesReportSource>> getTripExpensesSource({
    required String companyId,
    required DateTime? fromDate,
    required DateTime? toDate,
  }) async {
    final builder = expenses;
    if (builder == null) throw StateError('Unexpected expenses source call.');
    return Success(builder(companyId, fromDate, toDate));
  }

  @override
  Future<Result<TripNetProfitReportSource>> getTripNetProfitSource({
    required String companyId,
    required DateTime? fromDate,
    required DateTime? toDate,
  }) async {
    final builder = netProfit;
    if (builder == null) throw StateError('Unexpected net-profit source call.');
    return Success(builder(companyId, fromDate, toDate));
  }

  @override
  Future<Result<OpenInvoicesReportSource>> getOpenInvoicesSource({
    required String companyId,
    required DateTime? fromDate,
    required DateTime? toDate,
  }) async {
    final builder = openInvoices;
    if (builder == null) throw StateError('Unexpected open-invoices source call.');
    return Success(builder(companyId, fromDate, toDate));
  }
}
