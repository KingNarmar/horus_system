import 'package:test/test.dart';

import 'package:horus_system/core/domain/value_objects/business_date.dart';
import 'package:horus_system/core/domain/value_objects/currency_code.dart';
import 'package:horus_system/core/domain/value_objects/money.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/entities/current_company_context.dart';
import 'package:horus_system/features/expenses/domain/entities/expense_funding_source.dart';
import 'package:horus_system/features/invoices/domain/entities/invoice_status.dart';
import 'package:horus_system/features/reports/domain/entities/open_invoices_report.dart';
import 'package:horus_system/features/reports/domain/entities/operational_trip_report.dart';
import 'package:horus_system/features/reports/domain/entities/report_date_range.dart';
import 'package:horus_system/features/reports/domain/entities/report_export_document.dart';
import 'package:horus_system/features/reports/domain/entities/report_export_kind.dart';
import 'package:horus_system/features/reports/domain/entities/report_export_table.dart';
import 'package:horus_system/features/reports/domain/entities/report_source_metadata.dart';
import 'package:horus_system/features/reports/domain/entities/trip_expenses_report.dart';
import 'package:horus_system/features/reports/domain/entities/trip_net_profit_report.dart';
import 'package:horus_system/features/reports/domain/repositories/reports_repository.dart';
import 'package:horus_system/features/reports/domain/services/report_export_projector.dart';
import 'package:horus_system/features/reports/domain/usecases/get_open_invoices_report_usecase.dart';
import 'package:horus_system/features/reports/domain/usecases/get_trip_expenses_report_usecase.dart';
import 'package:horus_system/features/reports/domain/usecases/get_trip_net_profit_report_usecase.dart';
import 'package:horus_system/features/reports/domain/usecases/report_params.dart';
import 'package:horus_system/features/trips/domain/entities/trip_status.dart';

void main() {
  final money = (int minorUnits) =>
      Money(minorUnits: minorUnits, currency: CurrencyCode.tryParse('AED')!);
  final date = BusinessDate(year: 2026, month: 11, day: 21);
  final range = ReportDateRange(
    fromDate: BusinessDate(year: 2026, month: 11, day: 1),
    toDate: BusinessDate(year: 2026, month: 11, day: 30),
  );
  const company = Company(
    id: 'company-a',
    name: 'شركة الاختبار',
    baseCurrencyCode: 'AED',
    baseCurrencyFractionDigits: 2,
    businessTimezone: 'Asia/Dubai',
  );
  const context = CurrentCompanyContext(
    company: company,
    role: CompanyRole.accountant,
  );
  ReportSourceMetadata metadata() => ReportSourceMetadata(
    companyId: company.id,
    currency: CurrencyCode.tryParse('AED')!,
    baseCurrencyFractionDigits: 2,
    businessTimezone: 'Asia/Dubai',
    businessDate: date,
    fromDate: range.fromDate,
    toDate: range.toDate,
    sourceAsOfUtc: DateTime.utc(2026, 11, 21, 8),
  );
  final request = ReportParams(
    currentCompanyContext: context,
    dateRange: range,
  );

  ReportExportTable export(ReportExportKind kind, ReportExportContent content) {
    return const ReportExportProjector().project(
      ReportExportDocument(
        companyId: company.id,
        companyName: company.name,
        logoBytes: null,
        kind: kind,
        dateRange: range,
        generatedAtUtc: DateTime.utc(2026, 11, 21, 9),
        content: content,
      ),
    );
  }

  test(
    'expenses export equals authorized Domain rows and exact total',
    () async {
      TripExpenseReportRow expense(
        String id,
        int minorUnits,
        ExpenseFundingSource funding,
      ) => TripExpenseReportRow(
        expenseId: id,
        expenseDate: date,
        tripId: 'trip-a',
        tripNumber: 'TRIP-A',
        tripDate: date,
        customerId: 'customer-a',
        customerName: 'شركة العميل',
        loadingLocation: 'Dubai',
        unloadingLocation: 'Port',
        loadingOrderNumber: null,
        waybillNumber: null,
        expenseTypeId: 'fuel',
        expenseName: 'وقود',
        fundingSource: funding,
        amount: money(minorUnits),
      );
      final repository = _ReportsFixtureRepository(
        expenses: TripExpensesReportSource(
          metadata: metadata(),
          precisionLossCount: 0,
          negativeAmountCount: 0,
          currencyMismatchCount: 0,
          rows: [
            expense('expense-a', 1250, ExpenseFundingSource.company),
            expense('expense-b', 2750, ExpenseFundingSource.driverCash),
          ],
        ),
      );
      final result = await GetTripExpensesReportUseCase(repository)(request);
      expect(result.failureOrNull, isNull);
      final report = result.dataOrNull!;
      final table = export(
        ReportExportKind.tripExpenses,
        ReportExportExpensesContent(report),
      );

      expect(report.metadata.fromDate, range.fromDate);
      expect(report.metadata.toDate, range.toDate);
      expect(table.rowCount, report.rows.length);
      expect(table.currencyFractionDigits, 2);
      expect(
        [
          for (final row in table.rows)
            (row.last as ReportExportMoneyCell).value.minorUnits,
        ],
        [for (final row in report.rows) row.amount.minorUnits],
      );
      expect(
        [
          for (final row in table.rows)
            (row[4] as ReportExportFundingCell).value,
        ],
        [for (final row in report.rows) row.fundingSource],
      );
      expect(
        (table.totals.single.value as ReportExportMoneyCell).value,
        report.totalExpenses,
      );
      expect(report.totalExpenses.minorUnits, 4000);
    },
  );

  test(
    'profit export matches linked expenses and per-trip net amounts',
    () async {
      TripNetProfitSourceTrip trip(String id, int freight, TripStatus status) =>
          TripNetProfitSourceTrip(
            tripId: id,
            tripNumber: id,
            operationalDate: date,
            status: status,
            customerId: 'customer-a',
            customerName: 'Customer A',
            driverId: null,
            driverName: null,
            tractorHeadId: null,
            tractorHeadPlateNumber: null,
            trailerId: null,
            trailerPlateNumber: null,
            loadingLocation: 'Dubai',
            unloadingLocation: 'Port',
            loadingOrderNumber: null,
            waybillNumber: null,
            freight: money(freight),
          );
      final repository = _ReportsFixtureRepository(
        profit: TripNetProfitReportSource(
          metadata: metadata(),
          freightPrecisionLossCount: 0,
          negativeFreightCount: 0,
          expensePrecisionLossCount: 0,
          negativeExpenseCount: 0,
          expenseCurrencyMismatchCount: 0,
          trips: [
            trip('trip-a', 500000, TripStatus.delivered),
            trip('trip-b', 120000, TripStatus.cancelled),
          ],
          expenses: [
            TripNetProfitSourceExpense(
              expenseId: 'expense-a',
              tripId: 'trip-a',
              amount: money(20000),
            ),
            TripNetProfitSourceExpense(
              expenseId: 'expense-b',
              tripId: 'trip-a',
              amount: money(5000),
            ),
            TripNetProfitSourceExpense(
              expenseId: 'expense-c',
              tripId: 'trip-b',
              amount: money(2000),
            ),
          ],
        ),
      );
      final result = await GetTripNetProfitReportUseCase(
        repository: repository,
      )(request);
      expect(result.failureOrNull, isNull);
      final report = result.dataOrNull!;
      final table = export(
        ReportExportKind.tripNetProfit,
        ReportExportProfitContent(report),
      );

      expect(table.rowCount, report.rows.length);
      for (var i = 0; i < report.rows.length; i++) {
        final domainRow = report.rows[i];
        final cells = table.rows[i];
        expect(
          (cells[3] as ReportExportTripStatusCell).value,
          domainRow.trip.status,
        );
        expect(
          (cells[4] as ReportExportMoneyCell).value,
          domainRow.trip.freight,
        );
        expect(
          (cells[5] as ReportExportMoneyCell).value,
          domainRow.totalExpenses,
        );
        expect((cells[6] as ReportExportMoneyCell).value, domainRow.netProfit);
      }
      expect(
        [
          for (final total in table.totals)
            (total.value as ReportExportMoneyCell).value.minorUnits,
        ],
        [
          report.totalFreight.minorUnits,
          report.totalExpenses.minorUnits,
          report.totalNetProfit.minorUnits,
        ],
      );
      expect(report.totalFreight.minorUnits, 620000);
      expect(report.totalExpenses.minorUnits, 27000);
      expect(report.totalNetProfit.minorUnits, 593000);
    },
  );

  test(
    'open invoices excludes fully paid and preserves multiple payments',
    () async {
      OpenInvoiceSourceInvoice invoice(
        String id,
        InvoiceStatus status,
        int minorUnits,
      ) => OpenInvoiceSourceInvoice(
        invoiceId: id,
        invoiceNumber: 'INV-$id',
        customerId: 'customer-a',
        customerName: 'Customer A',
        status: status,
        total: money(minorUnits),
        issueDate: date,
        dueDate: null,
        issuedAt: DateTime.utc(2026, 11, 21, 8),
      );
      OpenInvoiceSourcePayment payment(
        String id,
        String invoiceId,
        int minorUnits,
      ) => OpenInvoiceSourcePayment(
        paymentId: id,
        invoiceId: invoiceId,
        amount: money(minorUnits),
        paymentDate: date,
        createdAt: DateTime.utc(2026, 11, 21, 8),
      );
      final repository = _ReportsFixtureRepository(
        invoices: OpenInvoicesReportSource(
          metadata: metadata(),
          invoiceCurrencyMismatchCount: 0,
          paymentCurrencyMismatchCount: 0,
          invalidInvoiceAmountCount: 0,
          invalidPaymentAmountCount: 0,
          missingIssueDateCount: 0,
          invoices: [
            invoice('issued', InvoiceStatus.issued, 100000),
            invoice('partial', InvoiceStatus.partiallyPaid, 120000),
            invoice('paid', InvoiceStatus.paid, 80000),
          ],
          payments: [
            payment('payment-a', 'partial', 40000),
            payment('payment-b', 'partial', 15000),
            payment('payment-c', 'paid', 80000),
          ],
        ),
      );
      final result = await GetOpenInvoicesReportUseCase(repository: repository)(
        request,
      );
      expect(result.failureOrNull, isNull);
      final report = result.dataOrNull!;
      final table = export(
        ReportExportKind.openInvoices,
        ReportExportInvoicesContent(report),
      );

      expect(report.rows.map((row) => row.invoice.invoiceId), [
        'issued',
        'partial',
      ]);
      expect(table.rowCount, report.rows.length);
      for (var i = 0; i < report.rows.length; i++) {
        final domainRow = report.rows[i];
        final cells = table.rows[i];
        expect(
          (cells[4] as ReportExportInvoiceStatusCell).value,
          domainRow.invoice.status,
        );
        expect(
          (cells[5] as ReportExportMoneyCell).value,
          domainRow.invoice.total,
        );
        expect((cells[6] as ReportExportMoneyCell).value, domainRow.paid);
        expect((cells[7] as ReportExportMoneyCell).value, domainRow.remaining);
      }
      expect(report.rows.last.paid.minorUnits, 55000);
      expect(report.rows.last.remaining.minorUnits, 65000);
      expect(report.totalOutstanding.minorUnits, 165000);
      expect(
        (table.totals.single.value as ReportExportMoneyCell).value,
        report.totalOutstanding,
      );
    },
  );
}

final class _ReportsFixtureRepository implements ReportsRepository {
  final TripExpensesReportSource? expenses;
  final TripNetProfitReportSource? profit;
  final OpenInvoicesReportSource? invoices;

  const _ReportsFixtureRepository({this.expenses, this.profit, this.invoices});

  @override
  Future<Result<OperationalTripReportSource>> getOperationalTripSource({
    required String companyId,
    required BusinessDate? fromDate,
    required BusinessDate? toDate,
  }) => throw StateError('Unexpected operational report source');

  @override
  Future<Result<TripExpensesReportSource>> getTripExpensesSource({
    required String companyId,
    required BusinessDate? fromDate,
    required BusinessDate? toDate,
  }) async => Success(expenses!);

  @override
  Future<Result<TripNetProfitReportSource>> getTripNetProfitSource({
    required String companyId,
    required BusinessDate? fromDate,
    required BusinessDate? toDate,
  }) async => Success(profit!);

  @override
  Future<Result<OpenInvoicesReportSource>> getOpenInvoicesSource({
    required String companyId,
    required BusinessDate? fromDate,
    required BusinessDate? toDate,
  }) async => Success(invoices!);
}
