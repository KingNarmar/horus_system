import '../entities/report_export_table.dart';
import '../entities/report_pdf_page_layout.dart';

/// One deterministic layout rule for both generation and print delivery.
abstract final class ReportPdfPageLayoutPolicy {
  static const int landscapeMinimumColumns = 6;

  static ReportPdfPageLayout forColumns(List<ReportExportColumn> columns) =>
      columns.length >= landscapeMinimumColumns
      ? ReportPdfPageLayout.a4Landscape
      : ReportPdfPageLayout.a4Portrait;
}
