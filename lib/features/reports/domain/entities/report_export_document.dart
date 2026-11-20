import 'dart:typed_data';

import 'open_invoices_report.dart';
import 'operational_trip_report.dart';
import 'report_date_range.dart';
import 'report_export_kind.dart';
import 'trip_expenses_report.dart';
import 'trip_net_profit_report.dart';

/// A fresh, domain-authorized report with tenant-specific display identity.
/// generatedAtUtc is a client document timestamp, NOT a server as-of value.
final class ReportExportDocument {
  final String companyId;
  final String companyName;
  final Uint8List? logoBytes;
  final ReportExportKind kind;
  final ReportDateRange dateRange;
  final DateTime generatedAtUtc;
  final ReportExportContent content;

  /// Source read-start time, never inferred from the device clock.
  DateTime? get sourceAsOfUtc => switch (content) {
    ReportExportOperationalContent(:final report) =>
      report.metadata.sourceAsOfUtc,
    ReportExportExpensesContent(:final report) => report.metadata.sourceAsOfUtc,
    ReportExportProfitContent(:final report) => report.metadata.sourceAsOfUtc,
    ReportExportInvoicesContent(:final report) => report.metadata.sourceAsOfUtc,
  };

  const ReportExportDocument({
    required this.companyId,
    required this.companyName,
    required this.logoBytes,
    required this.kind,
    required this.dateRange,
    required this.generatedAtUtc,
    required this.content,
  });
}

sealed class ReportExportContent {
  const ReportExportContent();
}

final class ReportExportOperationalContent extends ReportExportContent {
  final OperationalTripReport report;

  const ReportExportOperationalContent(this.report);
}

final class ReportExportExpensesContent extends ReportExportContent {
  final TripExpensesReport report;

  const ReportExportExpensesContent(this.report);
}

final class ReportExportProfitContent extends ReportExportContent {
  final TripNetProfitReport report;

  const ReportExportProfitContent(this.report);
}

final class ReportExportInvoicesContent extends ReportExportContent {
  final OpenInvoicesReport report;

  const ReportExportInvoicesContent(this.report);
}
