import '../entities/open_invoices_report.dart';
import '../entities/operational_trip_report.dart';
import '../entities/report_export_document.dart';
import '../entities/report_export_table.dart';
import '../entities/trip_expenses_report.dart';
import '../entities/trip_net_profit_report.dart';

/// Pure one-way mapping: existing Domain totals and rows -> typed export cells.
final class ReportExportProjector {
  const ReportExportProjector();

  ReportExportTable project(ReportExportDocument document) =>
      switch (document.content) {
        ReportExportOperationalContent(:final report) => _operational(report),
        ReportExportExpensesContent(:final report) => _expenses(report),
        ReportExportProfitContent(:final report) => _profit(report),
        ReportExportInvoicesContent(:final report) => _invoices(report),
      };

  ReportExportTable _operational(OperationalTripReport report) {
    if (report.dimension != OperationalReportDimension.day) {
      return ReportExportTable(
        columns: [_groupColumn(report.dimension), ReportExportColumn.tripCount],
        rows: [
          for (final group in report.groups)
            [
              ReportExportTextCell(_groupLabel(report.dimension, group)),
              ReportExportCountCell(group.tripCount),
            ],
        ],
        totals: [
          ReportExportTotal(
            label: ReportExportColumn.tripCount,
            value: ReportExportCountCell(report.totalTrips),
          ),
        ],
        currencyFractionDigits: 0,
      );
    }
    return ReportExportTable(
      columns: const [
        ReportExportColumn.trip,
        ReportExportColumn.date,
        ReportExportColumn.customer,
        ReportExportColumn.driver,
        ReportExportColumn.tractorHead,
        ReportExportColumn.trailer,
        ReportExportColumn.route,
        ReportExportColumn.status,
      ],
      rows: [
        for (final group in report.groups)
          for (final row in group.rows)
            [
              ReportExportTextCell(
                _tripReference(
                  tripNumber: row.tripNumber,
                  loadingOrder: row.loadingOrderNumber,
                  waybill: row.waybillNumber,
                  loading: row.loadingLocation,
                  unloading: row.unloadingLocation,
                ),
              ),
              ReportExportDateCell(row.operationalDate),
              ReportExportTextCell(row.customerName),
              ReportExportTextCell(row.driverName ?? ''),
              ReportExportTextCell(row.tractorHeadPlateNumber ?? ''),
              ReportExportTextCell(row.trailerPlateNumber ?? ''),
              ReportExportTextCell(
                _route(row.loadingLocation, row.unloadingLocation),
              ),
              ReportExportTripStatusCell(row.status),
            ],
      ],
      totals: [
        ReportExportTotal(
          label: ReportExportColumn.tripCount,
          value: ReportExportCountCell(report.totalTrips),
        ),
      ],
      currencyFractionDigits: 0,
    );
  }

  ReportExportTable _expenses(TripExpensesReport report) => ReportExportTable(
    columns: const [
      ReportExportColumn.date,
      ReportExportColumn.trip,
      ReportExportColumn.customer,
      ReportExportColumn.expense,
      ReportExportColumn.paidBy,
      ReportExportColumn.amount,
    ],
    rows: [
      for (final row in report.rows)
        [
          ReportExportDateCell(row.expenseDate),
          ReportExportTextCell(
            _tripReference(
              tripNumber: row.tripNumber,
              loadingOrder: row.loadingOrderNumber,
              waybill: row.waybillNumber,
              loading: row.loadingLocation,
              unloading: row.unloadingLocation,
            ),
          ),
          ReportExportTextCell(row.customerName),
          ReportExportTextCell(row.expenseName),
          ReportExportFundingCell(row.fundingSource),
          ReportExportMoneyCell(row.amount),
        ],
    ],
    totals: [
      ReportExportTotal(
        label: ReportExportColumn.totalExpenses,
        value: ReportExportMoneyCell(report.totalExpenses),
      ),
    ],
    currencyFractionDigits: report.metadata.baseCurrencyFractionDigits,
  );

  ReportExportTable _profit(TripNetProfitReport report) => ReportExportTable(
    columns: const [
      ReportExportColumn.trip,
      ReportExportColumn.date,
      ReportExportColumn.customer,
      ReportExportColumn.status,
      ReportExportColumn.freight,
      ReportExportColumn.totalExpenses,
      ReportExportColumn.netProfit,
    ],
    rows: [
      for (final row in report.rows)
        [
          ReportExportTextCell(
            _tripReference(
              tripNumber: row.trip.tripNumber,
              loadingOrder: row.trip.loadingOrderNumber,
              waybill: row.trip.waybillNumber,
              loading: row.trip.loadingLocation,
              unloading: row.trip.unloadingLocation,
            ),
          ),
          ReportExportDateCell(row.trip.operationalDate),
          ReportExportTextCell(row.trip.customerName),
          ReportExportTripStatusCell(row.trip.status),
          ReportExportMoneyCell(row.trip.freight),
          ReportExportMoneyCell(row.totalExpenses),
          ReportExportMoneyCell(row.netProfit),
        ],
    ],
    totals: [
      ReportExportTotal(
        label: ReportExportColumn.totalFreight,
        value: ReportExportMoneyCell(report.totalFreight),
      ),
      ReportExportTotal(
        label: ReportExportColumn.totalExpenses,
        value: ReportExportMoneyCell(report.totalExpenses),
      ),
      ReportExportTotal(
        label: ReportExportColumn.totalNetProfit,
        value: ReportExportMoneyCell(report.totalNetProfit),
      ),
    ],
    currencyFractionDigits: report.metadata.baseCurrencyFractionDigits,
  );

  ReportExportTable _invoices(OpenInvoicesReport report) => ReportExportTable(
    columns: const [
      ReportExportColumn.invoice,
      ReportExportColumn.customer,
      ReportExportColumn.issueDate,
      ReportExportColumn.dueDate,
      ReportExportColumn.status,
      ReportExportColumn.total,
      ReportExportColumn.paid,
      ReportExportColumn.remaining,
    ],
    rows: [
      for (final row in report.rows)
        [
          ReportExportTextCell(
            _text(row.invoice.invoiceNumber) ?? row.invoice.invoiceId,
          ),
          ReportExportTextCell(row.invoice.customerName),
          ReportExportDateCell(row.invoice.issueDate),
          ReportExportOptionalDateCell(row.invoice.dueDate),
          ReportExportInvoiceStatusCell(row.invoice.status),
          ReportExportMoneyCell(row.invoice.total),
          ReportExportMoneyCell(row.paid),
          ReportExportMoneyCell(row.remaining),
        ],
    ],
    totals: [
      ReportExportTotal(
        label: ReportExportColumn.totalOutstanding,
        value: ReportExportMoneyCell(report.totalOutstanding),
      ),
    ],
    currencyFractionDigits: report.metadata.baseCurrencyFractionDigits,
  );

  ReportExportColumn _groupColumn(OperationalReportDimension dimension) =>
      switch (dimension) {
        OperationalReportDimension.day => ReportExportColumn.date,
        OperationalReportDimension.customer => ReportExportColumn.customer,
        OperationalReportDimension.route => ReportExportColumn.route,
        OperationalReportDimension.driver => ReportExportColumn.driver,
        OperationalReportDimension.tractorHead =>
          ReportExportColumn.tractorHead,
        OperationalReportDimension.trailer => ReportExportColumn.trailer,
      };

  String _groupLabel(
    OperationalReportDimension dimension,
    OperationalTripReportGroup group,
  ) {
    final label = _text(group.entityLabel);
    if (label != null) return label;
    if (dimension != OperationalReportDimension.route || group.rows.isEmpty) {
      return '';
    }
    return _route(
      group.rows.first.loadingLocation,
      group.rows.first.unloadingLocation,
    );
  }

  String _tripReference({
    required String? tripNumber,
    required String? loadingOrder,
    required String? waybill,
    required String loading,
    required String unloading,
  }) {
    return _text(tripNumber) ??
        _text(loadingOrder) ??
        _text(waybill) ??
        _route(loading, unloading);
  }

  String _route(String loading, String unloading) {
    final start = _text(loading);
    final end = _text(unloading);
    if (start == null) return end ?? '';
    if (end == null) return start;
    return '$start - $end';
  }

  String? _text(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
