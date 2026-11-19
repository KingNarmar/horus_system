import 'package:pdf/pdf.dart';

/// PDF-specific dimensions; independent from responsive Flutter UI tokens.
abstract final class ReportPdfStyle {
  static const double margin = 32;
  static const double logoSize = 56;
  static const double headingSize = 16;
  static const double textSize = 9;
  static const double smallSize = 7;
  static const double tableTextSize = 7;
  static const double tablePadding = 5;
  static const double sectionGap = 12;
  static const PdfColor tableHeader = PdfColors.grey200;
  static const PdfColor tableBorder = PdfColors.grey400;
}
