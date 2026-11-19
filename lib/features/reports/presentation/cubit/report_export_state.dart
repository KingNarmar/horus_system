import 'dart:typed_data';

import '../../../../core/errors/failure.dart';
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
  const ReportExportBusy(this.action);
}

final class ReportExportPreviewReady extends ReportExportState {
  final Uint8List bytes;
  const ReportExportPreviewReady(this.bytes);
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
