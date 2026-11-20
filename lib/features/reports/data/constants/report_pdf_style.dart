import 'package:pdf/pdf.dart';

/// PDF-specific dimensions; independent from responsive Flutter UI tokens.
abstract final class ReportPdfStyle {
  /// Report rows may each need a page; reserve pages for title and totals.
  /// Unlike a fixed page cap, this preserves complete large exports while
  /// keeping the PDF engine's runaway-pagination guard enabled.
  static const int nonTablePaginationPages = 3;
  static const double margin = 32;
  static const double logoSize = 56;
  static const double headingSize = 16;
  static const double textSize = 9;
  static const double smallSize = 8;
  static const double tableTextSize = 9;
  static const double tablePadding = 6;
  static const double defaultColumnFlex = 1;
  static const double tripColumnFlex = 1.8;
  static const double dateColumnFlex = 1.5;
  static const double descriptionColumnFlex = 1.8;
  static const double routeColumnFlex = 2.1;
  static const double identifierColumnFlex = 1.35;
  static const double statusColumnFlex = 1.4;
  static const double moneyColumnFlex = 1.5;
  static const double sectionGap = 12;
  static const PdfColor tableHeader = PdfColors.grey200;
  static const PdfColor tableBorder = PdfColors.grey400;
}
