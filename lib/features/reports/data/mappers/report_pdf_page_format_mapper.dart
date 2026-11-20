import 'package:pdf/pdf.dart';

import '../../domain/entities/report_pdf_page_layout.dart';

/// Converts the pure report page contract to the PDF/printer SDK geometry.
abstract final class ReportPdfPageFormatMapper {
  static PdfPageFormat toPdfFormat(ReportPdfPageLayout layout) =>
      switch (layout) {
        ReportPdfPageLayout.a4Portrait => PdfPageFormat.a4,
        ReportPdfPageLayout.a4Landscape => PdfPageFormat.a4.landscape,
      };
}
