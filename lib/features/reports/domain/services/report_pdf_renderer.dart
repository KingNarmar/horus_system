import 'dart:typed_data';

import '../../../../core/utils/result.dart';
import '../entities/report_export_document.dart';
import '../entities/report_export_labels.dart';
import '../entities/report_export_table.dart';
import '../entities/report_pdf_page_layout.dart';

/// No PDF SDK, Flutter, files or platform imports in this contract.
abstract interface class ReportPdfRenderer {
  Future<Result<Uint8List>> render({
    required ReportExportDocument document,
    required ReportExportTable table,
    required ReportExportLabels labels,
    required ReportPdfPageLayout pageLayout,
  });
}
