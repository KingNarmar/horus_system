import 'package:flutter/widgets.dart';

import '../../../../core/localization/app_localizations_extension.dart';
import '../../../expenses/domain/entities/expense_funding_source.dart';
import '../../../invoices/domain/entities/invoice_status.dart';
import '../../../trips/domain/entities/trip_status.dart';
import '../../../trips/presentation/localization/trips_localizations_x.dart';
import '../../domain/entities/report_export_kind.dart';
import '../../domain/entities/report_export_labels.dart';
import '../../domain/entities/report_export_table.dart';
import '../cubit/report_type.dart';
import 'reports_localizations.dart';

extension ReportExportLabelsX on BuildContext {
  ReportExportLabels get reportExportLabels {
    final strings = reportsL10n;
    return ReportExportLabels(
      isRtl: Localizations.localeOf(this).languageCode == 'ar',
      localeName: Localizations.localeOf(this).toLanguageTag(),
      period: strings.exportPdfPeriod,
      generatedAt: strings.exportPdfGeneratedAt,
      page: strings.exportPdfPage,
      noRows: strings.noRows,
      allDates: strings.allDates,
      unassigned: strings.unassigned,
      unavailable: strings.notAvailable,
      titles: {
        for (final kind in ReportExportKind.values)
          kind: strings.reportTypeLabel(_reportType(kind)),
      },
      columns: {
        for (final column in ReportExportColumn.values)
          column: _columnLabel(strings, column),
      },
      tripStatuses: {
        for (final status in TripStatus.values)
          status: l10n.tripStatusLabel(status),
      },
      invoiceStatuses: {
        for (final status in InvoiceStatus.values)
          status: strings.invoiceStatusLabel(status),
      },
      fundingSources: {
        for (final source in ExpenseFundingSource.values)
          source: strings.fundingSourceLabel(source),
      },
    );
  }
}

ReportType _reportType(ReportExportKind kind) => switch (kind) {
  ReportExportKind.dailyTrips => ReportType.dailyTrips,
  ReportExportKind.tripsByCustomer => ReportType.tripsByCustomer,
  ReportExportKind.tripsByRoute => ReportType.tripsByRoute,
  ReportExportKind.tripsByDriver => ReportType.tripsByDriver,
  ReportExportKind.tripsByTractorHead => ReportType.tripsByTractorHead,
  ReportExportKind.tripsByTrailer => ReportType.tripsByTrailer,
  ReportExportKind.tripExpenses => ReportType.tripExpenses,
  ReportExportKind.tripNetProfit => ReportType.tripNetProfit,
  ReportExportKind.openInvoices => ReportType.openInvoices,
};

String _columnLabel(ReportsLocalizations s, ReportExportColumn column) =>
    switch (column) {
      ReportExportColumn.group => s.reportLabel,
      ReportExportColumn.tripCount => s.tripsCount,
      ReportExportColumn.trip => s.trip,
      ReportExportColumn.date => s.date,
      ReportExportColumn.customer => s.customer,
      ReportExportColumn.driver => s.driver,
      ReportExportColumn.tractorHead => s.tractorHead,
      ReportExportColumn.trailer => s.trailer,
      ReportExportColumn.route => s.route,
      ReportExportColumn.status => s.status,
      ReportExportColumn.expense => s.expense,
      ReportExportColumn.paidBy => s.paidBy,
      ReportExportColumn.amount => s.amount,
      ReportExportColumn.freight => s.freight,
      ReportExportColumn.totalExpenses => s.totalExpenses,
      ReportExportColumn.netProfit => s.netProfit,
      ReportExportColumn.invoice => s.invoice,
      ReportExportColumn.issueDate => s.issueDate,
      ReportExportColumn.dueDate => s.dueDate,
      ReportExportColumn.total => s.total,
      ReportExportColumn.paid => s.paid,
      ReportExportColumn.remaining => s.remaining,
      ReportExportColumn.totalFreight => s.totalFreight,
      ReportExportColumn.totalNetProfit => s.totalNetProfit,
      ReportExportColumn.totalOutstanding => s.totalOutstanding,
    };
