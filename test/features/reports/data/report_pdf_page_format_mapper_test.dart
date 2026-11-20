import 'package:test/test.dart';
import 'package:pdf/pdf.dart';

import 'package:horus_system/features/reports/data/mappers/report_pdf_page_format_mapper.dart';
import 'package:horus_system/features/reports/domain/entities/report_pdf_page_layout.dart';

void main() {
  test('the print adapter and renderer get identical physical A4 geometry', () {
    final portrait = ReportPdfPageFormatMapper.toPdfFormat(
      ReportPdfPageLayout.a4Portrait,
    );
    final landscape = ReportPdfPageFormatMapper.toPdfFormat(
      ReportPdfPageLayout.a4Landscape,
    );
    expect(portrait.width, PdfPageFormat.a4.width);
    expect(portrait.height, PdfPageFormat.a4.height);
    expect(landscape.width, PdfPageFormat.a4.height);
    expect(landscape.height, PdfPageFormat.a4.width);
    expect(portrait.height, greaterThan(portrait.width));
    expect(landscape.width, greaterThan(landscape.height));
  });
}
