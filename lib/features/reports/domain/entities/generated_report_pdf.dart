import 'dart:typed_data';

import 'report_pdf_page_layout.dart';

final class GeneratedReportPdf {
  final Uint8List bytes;
  final String fileName;
  final ReportPdfPageLayout pageLayout;

  const GeneratedReportPdf({
    required this.bytes,
    required this.fileName,
    required this.pageLayout,
  });
}
