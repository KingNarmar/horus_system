import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../../../../core/errors/common_failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/failures/reports_failure_codes.dart';
import '../../domain/entities/report_pdf_page_layout.dart';
import '../../domain/repositories/report_pdf_delivery_repository.dart';
import '../constants/report_pdf_share_constants.dart';
import '../mappers/report_pdf_page_format_mapper.dart';
import '../services/report_pdf_share_service.dart';

typedef ReportPdfPrintDelegate = Future<bool> Function({
  required Uint8List bytes,
  required String fileName,
  required PdfPageFormat pageFormat,
});

final class ReportPdfDeliveryRepositoryImpl
    implements ReportPdfDeliveryRepository {
  final ReportPdfShareService _shareService;
  final ReportPdfPrintDelegate _printDelegate;

  ReportPdfDeliveryRepositoryImpl({
    ReportPdfShareService? shareService,
    ReportPdfPrintDelegate? printDelegate,
  }) : _shareService = shareService ?? ReportPdfShareService(),
       _printDelegate = printDelegate ?? _nativePrint;

  @override
  Future<Result<ReportPdfDeliveryOutcome>> save({
    required Uint8List bytes,
    required String fileName,
  }) async {
    try {
      final path = await FilePicker.saveFile(
        fileName: fileName,
        bytes: bytes,
        mimeType: ReportPdfShareConstants.mimeType,
      );
      return Success(
        path == null
            ? ReportPdfDeliveryOutcome.cancelled
            : ReportPdfDeliveryOutcome.completed,
      );
    } catch (_) {
      return const FailureResult(
        ServerFailure(code: ReportsFailureCodes.pdfSaveUnavailable),
      );
    }
  }

  @override
  Future<Result<ReportPdfDeliveryOutcome>> print({
    required Uint8List bytes,
    required String fileName,
    required ReportPdfPageLayout pageLayout,
  }) async {
    try {
      final printed = await _printDelegate(
        bytes: bytes,
        fileName: fileName,
        pageFormat: ReportPdfPageFormatMapper.toPdfFormat(pageLayout),
      );
      return Success(
        printed
            ? ReportPdfDeliveryOutcome.completed
            : ReportPdfDeliveryOutcome.cancelled,
      );
    } catch (_) {
      return const FailureResult(
        ServerFailure(code: ReportsFailureCodes.pdfPrintUnavailable),
      );
    }
  }

  static Future<bool> _nativePrint({
    required Uint8List bytes,
    required String fileName,
    required PdfPageFormat pageFormat,
  }) => Printing.layoutPdf(
    name: fileName,
    format: pageFormat,
    onLayout: (_) async => bytes,
  );

  @override
  Future<Result<ReportPdfDeliveryOutcome>> share({
    required Uint8List bytes,
    required String fileName,
  }) async {
    try {
      return Success(
        await _shareService.share(bytes: bytes, fileName: fileName),
      );
    } catch (_) {
      return const FailureResult(
        ServerFailure(code: ReportsFailureCodes.pdfShareUnavailable),
      );
    }
  }
}
