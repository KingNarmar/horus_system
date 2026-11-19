import '../../../expenses/domain/entities/expense_funding_source.dart';
import '../../../invoices/domain/entities/invoice_status.dart';
import '../../../trips/domain/entities/trip_status.dart';
import 'report_export_kind.dart';
import 'report_export_table.dart';

/// Resolved English/Arabic text, injected at the Presentation boundary.
final class ReportExportLabels {
  final bool isRtl;
  final String localeName;
  final String period;
  final String generatedAt;
  final String page;
  final String noRows;
  final String allDates;
  final String unassigned;
  final String unavailable;
  final Map<ReportExportKind, String> titles;
  final Map<ReportExportColumn, String> columns;
  final Map<TripStatus, String> tripStatuses;
  final Map<InvoiceStatus, String> invoiceStatuses;
  final Map<ExpenseFundingSource, String> fundingSources;

  ReportExportLabels({
    required this.isRtl,
    required this.localeName,
    required this.period,
    required this.generatedAt,
    required this.page,
    required this.noRows,
    required this.allDates,
    required this.unassigned,
    required this.unavailable,
    required Map<ReportExportKind, String> titles,
    required Map<ReportExportColumn, String> columns,
    required Map<TripStatus, String> tripStatuses,
    required Map<InvoiceStatus, String> invoiceStatuses,
    required Map<ExpenseFundingSource, String> fundingSources,
  }) : titles = Map.unmodifiable(titles),
       columns = Map.unmodifiable(columns),
       tripStatuses = Map.unmodifiable(tripStatuses),
       invoiceStatuses = Map.unmodifiable(invoiceStatuses),
       fundingSources = Map.unmodifiable(fundingSources);
}
