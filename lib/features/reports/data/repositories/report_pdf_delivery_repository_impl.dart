import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../../../../core/errors/common_failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/failures/reports_failure_codes.dart';
import '../../domain/repositories/report_pdf_delivery_repository.dart';
import '../constants/report_pdf_share_constants.dart';
import '../services/report_pdf_share_service.dart';

final class ReportPdfDeliveryRepositoryImpl
    implements ReportPdfDeliveryRepository {
  final ReportPdfShareService _shareService;

  ReportPdfDeliveryRepositoryImpl({ReportPdfShareService? shareService})
    : _shareService = shareService ?? ReportPdfShareService();

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
  }) async {
    try {
      final printed = await Printing.layoutPdf(
        name: fileName,
        format: PdfPageFormat.a4,
        onLayout: (_) async => bytes,
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
