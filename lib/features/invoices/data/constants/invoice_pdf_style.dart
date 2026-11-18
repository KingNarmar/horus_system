import 'package:pdf/pdf.dart';

/// Fixed page-style tokens for issued business documents. This is a PDF
/// design system, intentionally independent from Flutter screen dimensions.
abstract final class InvoicePdfStyle {
  static const double pageMargin = 36;
  static const double headingSize = 18;
  static const double issuerSize = 15;
  static const double bodySize = 9;
  static const double smallSize = 8;
  static const double sectionGap = 18;
  static const double itemGap = 6;
  static const double logoSize = 68;
  static const double customerHeadingSize = 11;
  static const PdfColor statusBorder = PdfColors.grey500;
  static const PdfColor tableHeader = PdfColors.grey200;
  static const double tablePadding = 6;
  static const double tripColumnFlex = 1.6;
  static const double dateColumnFlex = 1.3;
  static const double routeColumnFlex = 2.6;
  static const double routeArrowWidth = 10;
  static const double routeArrowHeight = 9;
  static const double routeArrowHeadSize = 4;
  static const double routeArrowStroke = 0.9;
  static const double quantityColumnFlex = 1.2;
  static const double amountColumnFlex = 1.3;
  static const double statusPadding = 8;
}
