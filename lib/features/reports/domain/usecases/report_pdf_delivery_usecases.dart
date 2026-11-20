import 'dart:typed_data';

import '../../../../core/errors/common_failures.dart';
import '../../../../core/utils/result.dart';
import '../failures/reports_failure_codes.dart';
import '../entities/report_pdf_page_layout.dart';
import '../repositories/report_pdf_delivery_repository.dart';

final class ReportPdfDeliveryParams {
  final Uint8List bytes;
  final String fileName;
  final ReportPdfPageLayout? pageLayout;

  const ReportPdfDeliveryParams({
    required this.bytes,
    required this.fileName,
    this.pageLayout,
  });
}

abstract final class _PdfDeliveryValidation {
  static Result<void> validate(ReportPdfDeliveryParams params) =>
      params.bytes.isNotEmpty && params.fileName.endsWith('.pdf')
      ? const Success<void>(null)
      : const FailureResult<void>(
          ValidationFailure(code: ReportsFailureCodes.pdfInvalidDocument),
        );
}

final class SaveReportPdfUseCase {
  final ReportPdfDeliveryRepository _repository;
  const SaveReportPdfUseCase(this._repository);

  Future<Result<ReportPdfDeliveryOutcome>> call(
    ReportPdfDeliveryParams params,
  ) async {
    final checked = _PdfDeliveryValidation.validate(params);
    if (checked.failureOrNull != null) {
      return FailureResult(checked.failureOrNull!);
    }
    return _repository.save(bytes: params.bytes, fileName: params.fileName);
  }
}

final class PrintReportPdfUseCase {
  final ReportPdfDeliveryRepository _repository;
  const PrintReportPdfUseCase(this._repository);

  Future<Result<ReportPdfDeliveryOutcome>> call(
    ReportPdfDeliveryParams params,
  ) async {
    final checked = _PdfDeliveryValidation.validate(params);
    if (checked.failureOrNull != null) {
      return FailureResult(checked.failureOrNull!);
    }
    final pageLayout = params.pageLayout;
    if (pageLayout == null) {
      return const FailureResult(
        ValidationFailure(code: ReportsFailureCodes.pdfInvalidDocument),
      );
    }
    return _repository.print(
      bytes: params.bytes,
      fileName: params.fileName,
      pageLayout: pageLayout,
    );
  }
}

final class ShareReportPdfUseCase {
  final ReportPdfDeliveryRepository _repository;
  const ShareReportPdfUseCase(this._repository);

  Future<Result<ReportPdfDeliveryOutcome>> call(
    ReportPdfDeliveryParams params,
  ) async {
    final checked = _PdfDeliveryValidation.validate(params);
    if (checked.failureOrNull != null) {
      return FailureResult(checked.failureOrNull!);
    }
    return _repository.share(bytes: params.bytes, fileName: params.fileName);
  }
}
