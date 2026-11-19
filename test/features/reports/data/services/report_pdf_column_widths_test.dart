import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:horus_system/features/reports/data/services/report_pdf_column_widths.dart';
import 'package:horus_system/features/reports/domain/entities/report_export_table.dart';

void main() {
  test('eight-column daily trip report receives semantic PDF widths', () {
    final widths = ReportPdfColumnWidths.forColumns(const [
      ReportExportColumn.trip,
      ReportExportColumn.date,
      ReportExportColumn.customer,
      ReportExportColumn.driver,
      ReportExportColumn.tractorHead,
      ReportExportColumn.trailer,
      ReportExportColumn.route,
      ReportExportColumn.status,
    ]);

    expect(widths.keys.toList(), List<int>.generate(8, (i) => i));
    expect(widths.values, everyElement(isA<pw.FlexColumnWidth>()));
  });

  test('two-column grouped report also receives PDF widths', () {
    final widths = ReportPdfColumnWidths.forColumns(const [
      ReportExportColumn.route,
      ReportExportColumn.tripCount,
    ]);

    expect(widths.keys.toList(), [0, 1]);
  });
}
