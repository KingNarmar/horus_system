import 'dart:typed_data';

import '../../../../core/errors/failure.dart';
import '../../domain/entities/generated_report_pdf.dart';
import '../../domain/entities/report_export_progress.dart';
import '../../domain/repositories/report_pdf_delivery_repository.dart';

enum ReportPdfAction { preview, save, print, share }

sealed class ReportExportState {
  const ReportExportState();
}

final class ReportExportIdle extends ReportExportState {
  const ReportExportIdle();
}

final class ReportExportBusy extends ReportExportState {
  final ReportPdfAction action;
  final ReportExportProgress progress;

  const ReportExportBusy(
    this.action, {
    this.progress = const ReportExportProgress(
      stage: ReportExportStage.readingSource,
    ),
  });
}

final class ReportExportPreviewReady extends ReportExportState {
  final Uint8List bytes;
  const ReportExportPreviewReady(this.bytes);
}

/// The exact authorized bytes that will be printed once reauthorized.
final class ReportExportPrintPreviewReady extends ReportExportState {
  final GeneratedReportPdf document;
  const ReportExportPrintPreviewReady(this.document);
}

final class ReportExportCompleted extends ReportExportState {
  final ReportPdfAction action;
  final ReportPdfDeliveryOutcome outcome;
  const ReportExportCompleted(this.action, this.outcome);
}

final class ReportExportFailed extends ReportExportState {
  final Failure failure;
  const ReportExportFailed(this.failure);
}
