import 'package:test/test.dart';

import 'package:horus_system/features/reports/domain/entities/report_export_table.dart';
import 'package:horus_system/features/reports/domain/entities/report_pdf_page_layout.dart';
import 'package:horus_system/features/reports/domain/policies/report_pdf_page_layout_policy.dart';

void main() {
  test('narrow reports use portrait and wide reports use landscape', () {
    final columns = ReportExportColumn.values.toList();
    expect(
      ReportPdfPageLayoutPolicy.forColumns(columns.take(5).toList()),
      ReportPdfPageLayout.a4Portrait,
    );
    expect(
      ReportPdfPageLayoutPolicy.forColumns(columns.take(6).toList()),
      ReportPdfPageLayout.a4Landscape,
    );
    expect(
      ReportPdfPageLayoutPolicy.forColumns(columns.take(8).toList()),
      ReportPdfPageLayout.a4Landscape,
    );
  });
}
