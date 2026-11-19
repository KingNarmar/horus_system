import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../services/invoice_pdf_share_service.dart';

import '../../../../core/errors/common_failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/failures/invoice_failure_codes.dart';
import '../../domain/repositories/invoice_pdf_delivery_repository.dart';

/// Owns the only platform-specific PDF I/O in the invoice feature.
final class InvoicePdfDeliveryRepositoryImpl
    implements InvoicePdfDeliveryRepository {
  final InvoicePdfShareService _shareService;

  InvoicePdfDeliveryRepositoryImpl({InvoicePdfShareService? shareService})
    : _shareService = shareService ?? InvoicePdfShareService();

  @override
  Future<Result<InvoicePdfDeliveryOutcome>> save({
    required Uint8List bytes,
    required String fileName,
  }) async {
    try {
      final destination = await FilePicker.saveFile(
        fileName: fileName,
        bytes: bytes,
        mimeType: 'application/pdf',
      );
      return Success(
        destination == null
            ? InvoicePdfDeliveryOutcome.cancelled
            : InvoicePdfDeliveryOutcome.completed,
      );
    } catch (_) {
      return const FailureResult(
        ServerFailure(code: InvoiceFailureCodes.pdfSaveUnavailable),
      );
    }
  }

  @override
  Future<Result<InvoicePdfDeliveryOutcome>> print({
    required Uint8List bytes,
    required String fileName,
  }) async {
    try {
      final completed = await Printing.layoutPdf(
        name: fileName,
        format: PdfPageFormat.a4,
        onLayout: (_) async => bytes,
      );
      return Success(
        completed
            ? InvoicePdfDeliveryOutcome.completed
            : InvoicePdfDeliveryOutcome.cancelled,
      );
    } catch (_) {
      return const FailureResult(
        ServerFailure(code: InvoiceFailureCodes.pdfPrintUnavailable),
      );
    }
  }

  @override
  Future<Result<InvoicePdfDeliveryOutcome>> share({
    required Uint8List bytes,
    required String fileName,
  }) async {
    try {
      final outcome = await _shareService.share(
        bytes: bytes,
        fileName: fileName,
      );
      return Success(outcome);
    } catch (_) {
      return const FailureResult(
        ServerFailure(code: InvoiceFailureCodes.pdfShareUnavailable),
      );
    }
  }
}
