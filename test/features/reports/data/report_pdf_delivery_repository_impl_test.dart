import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:test/test.dart';

import 'package:horus_system/features/reports/data/repositories/report_pdf_delivery_repository_impl.dart';
import 'package:horus_system/features/reports/domain/entities/report_pdf_page_layout.dart';
import 'package:horus_system/features/reports/domain/repositories/report_pdf_delivery_repository.dart';

void main() {
  test(
    'native printing receives landscape geometry and original PDF bytes',
    () async {
      final bytes = Uint8List.fromList([37, 80, 68, 70]);
      late Uint8List capturedBytes;
      late String capturedName;
      late PdfPageFormat capturedFormat;
      final repository = ReportPdfDeliveryRepositoryImpl(
        printDelegate:
            ({
              required Uint8List bytes,
              required String fileName,
              required PdfPageFormat pageFormat,
            }) async {
              capturedBytes = bytes;
              capturedName = fileName;
              capturedFormat = pageFormat;
              return true;
            },
      );

      final result = await repository.print(
        bytes: bytes,
        fileName: 'wide.pdf',
        pageLayout: ReportPdfPageLayout.a4Landscape,
      );

      expect(result.dataOrNull, ReportPdfDeliveryOutcome.completed);
      expect(identical(capturedBytes, bytes), isTrue);
      expect(capturedName, 'wide.pdf');
      expect(capturedFormat.width, PdfPageFormat.a4.height);
      expect(capturedFormat.height, PdfPageFormat.a4.width);
    },
  );

  test('printer cancellation is not falsely reported as printed', () async {
    final repository = ReportPdfDeliveryRepositoryImpl(
      printDelegate:
          ({
            required Uint8List bytes,
            required String fileName,
            required PdfPageFormat pageFormat,
          }) async => false,
    );
    final result = await repository.print(
      bytes: Uint8List.fromList([37, 80, 68, 70]),
      fileName: 'narrow.pdf',
      pageLayout: ReportPdfPageLayout.a4Portrait,
    );
    expect(result.dataOrNull, ReportPdfDeliveryOutcome.cancelled);
  });
}
