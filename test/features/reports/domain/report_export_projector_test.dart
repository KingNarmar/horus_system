import 'package:test/test.dart';

import 'package:horus_system/core/domain/value_objects/business_date.dart';
import 'package:horus_system/core/domain/value_objects/currency_code.dart';
import 'package:horus_system/core/domain/value_objects/money.dart';
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
import 'package:horus_system/features/reports/domain/services/report_export_projector.dart';
import 'package:horus_system/features/trips/domain/entities/trip_status.dart';

void main() {
  final date = BusinessDate(year: 2026, month: 11, day: 19);
  final currency = CurrencyCode.tryParse('AED')!;
  final total = Money(minorUnits: 1234567, currency: currency);
  final expense = Money(minorUnits: 4567, currency: currency);
  final financialMetadata = ReportSourceMetadata(
    companyId: 'company-a',
    currency: currency,
    baseCurrencyFractionDigits: 2,
    businessTimezone: 'Asia/Dubai',
    businessDate: date,
    fromDate: null,
    toDate: null,
  );
  final operationalMetadata = OperationalReportSourceMetadata(
    companyId: 'company-a',
    businessTimezone: 'Asia/Dubai',
    businessDate: date,
    fromDate: null,
    toDate: null,
  );
  const projector = ReportExportProjector();

  ReportExportDocument document(
    ReportExportContent content,
    ReportExportKind kind,
  ) => ReportExportDocument(
    companyId: 'company-a',
    companyName: 'Test',
    logoBytes: null,
    kind: kind,
    dateRange: const ReportDateRange(),
    generatedAtUtc: DateTime.utc(2026, 11, 19),
    content: content,
  );

  test('daily trips preserve the individual Domain rows and date types', () {
    final row = OperationalTripReportRow(
      tripId: 'trip-a',
      tripNumber: 'TRIP-1',
      operationalDate: date,
      status: TripStatus.created,
      customerId: 'customer-a',
      customerName: 'Customer A',
      driverId: null,
      driverName: null,
      tractorHeadId: null,
      tractorHeadPlateNumber: null,
      trailerId: null,
      trailerPlateNumber: null,
      routeId: 'route-a',
      loadingLocation: 'Dubai',
      unloadingLocation: 'Sharjah',
      loadingOrderNumber: null,
      waybillNumber: null,
      cargoType: null,
      quantityTons: null,
    );
    final group = OperationalTripReportGroup(
      date: date,
      entityId: null,
      entityLabel: null,
      rows: [row],
    );
    final report = OperationalTripReport(
      metadata: operationalMetadata,
      dimension: OperationalReportDimension.day,
      groups: [group],
    );
    final result = projector.project(document(
      ReportExportOperationalContent(report),
      ReportExportKind.dailyTrips,
    ));
    expect(result.rowCount, 1);
    expect(result.columns, contains(ReportExportColumn.date));
    expect(result.rows.single[1], isA<ReportExportDateCell>());
    expect(result.rows.single.last, isA<ReportExportTripStatusCell>());
    expect((result.totals.single.value as ReportExportCountCell).value, 1);
  });

  test('all five grouped operational dimensions preserve group counts', () {
    for (final dimension in OperationalReportDimension.values.skip(1)) {
      final group = OperationalTripReportGroup(
        date: null,
        entityId: 'group-a',
        entityLabel: 'Assigned group',
        rows: [],
      );
      final report = OperationalTripReport(
        metadata: operationalMetadata,
        dimension: dimension,
        groups: [group],
      );
      final value = projector.project(document(
        ReportExportOperationalContent(report),
        ReportExportKind.tripsByCustomer,
      ));
      expect(value.rowCount, 1);
      expect(value.columns.length, 2);
      expect(value.rows.single.first, isA<ReportExportTextCell>());
      expect(value.rows.single.last, isA<ReportExportCountCell>());
    }
  });

  test('expenses retain exact minor units and funding source', () {
    final report = TripExpensesReport(
      metadata: financialMetadata,
      totalExpenses: expense,
      rows: [
        TripExpenseReportRow(
          expenseId: 'expense-a',
          expenseDate: date,
          tripId: 'trip-a',
          tripNumber: 'T-01',
          tripDate: date,
          customerId: 'customer-a',
          customerName: 'Customer A',
          loadingLocation: 'Dubai',
          unloadingLocation: 'Abu Dhabi',
          loadingOrderNumber: null,
          waybillNumber: null,
          expenseTypeId: 'type-a',
          expenseName: 'Fuel',
          fundingSource: ExpenseFundingSource.company,
          amount: expense,
        ),
      ],
    );
    final value = projector.project(document(
      ReportExportExpensesContent(report),
      ReportExportKind.tripExpenses,
    ));
    expect(value.currencyFractionDigits, 2);
    expect(value.rows.single[4], isA<ReportExportFundingCell>());
    expect((value.rows.single.last as ReportExportMoneyCell).value, expense);
    expect((value.totals.single.value as ReportExportMoneyCell).value, expense);
  });

  test('profit exports original Domain totals without recomputing', () {
    final trip = TripNetProfitSourceTrip(
      tripId: 'trip-a',
      tripNumber: 'T-01',
      operationalDate: date,
      status: TripStatus.delivered,
      customerId: 'customer-a',
      customerName: 'Customer A',
      driverId: null,
      driverName: null,
      tractorHeadId: null,
      tractorHeadPlateNumber: null,
      trailerId: null,
      trailerPlateNumber: null,
      loadingLocation: 'Dubai',
      unloadingLocation: 'Sharjah',
      loadingOrderNumber: null,
      waybillNumber: null,
      freight: total,
    );
    final profit = Money(minorUnits: 1230000, currency: currency);
    final report = TripNetProfitReport(
      metadata: financialMetadata,
      rows: [
        TripNetProfitReportRow(
          trip: trip,
          totalExpenses: expense,
          netProfit: profit,
        ),
      ],
      totalFreight: total,
      totalExpenses: expense,
      totalNetProfit: profit,
    );
    final value = projector.project(document(
      ReportExportProfitContent(report),
      ReportExportKind.tripNetProfit,
    ));
    expect(value.rowCount, 1);
    expect(
      (value.rows.single.last as ReportExportMoneyCell).value.minorUnits,
      1230000,
    );
    expect((value.totals.last.value as ReportExportMoneyCell).value, profit);
  });

  test('invoice date cells and approved outstanding balance remain typed', () {
    final invoice = OpenInvoiceSourceInvoice(
      invoiceId: 'invoice-a',
      invoiceNumber: 'INV-1',
      customerId: 'customer-a',
      customerName: 'Customer A',
      status: InvoiceStatus.partiallyPaid,
      total: total,
      issueDate: date,
      dueDate: null,
      issuedAt: null,
    );
    final report = OpenInvoicesReport(
      metadata: financialMetadata,
      rows: [
        OpenInvoiceReportRow(
          invoice: invoice,
          paid: expense,
          remaining: total,
        ),
      ],
      totalOutstanding: total,
    );
    final value = projector.project(document(
      ReportExportInvoicesContent(report),
      ReportExportKind.openInvoices,
    ));
    expect(value.rowCount, 1);
    expect(value.rows.single[2], isA<ReportExportDateCell>());
    expect(value.rows.single[3], isA<ReportExportOptionalDateCell>());
    expect(value.rows.single[4], isA<ReportExportInvoiceStatusCell>());
    expect(
      (value.totals.single.value as ReportExportMoneyCell).value.minorUnits,
      1234567,
    );
  });
}
