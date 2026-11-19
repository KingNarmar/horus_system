import 'dart:typed_data';

import '../../../../core/utils/result.dart';
import '../entities/report_export_document.dart';
import '../entities/report_export_labels.dart';
import '../services/report_export_projector.dart';
import '../services/report_pdf_renderer.dart';
import 'prepare_report_export_usecase.dart';

final class GenerateReportPdfParams {
  final PrepareReportExportParams report;
  final ReportExportLabels labels;

  const GenerateReportPdfParams({
    required this.report,
    required this.labels,
  });
}

/// Export authorization and source retrieval happen before PDF serialization.
final class GenerateReportPdfUseCase {
  final PrepareReportExportUseCase _prepare;
  final ReportExportProjector _projector;
  final ReportPdfRenderer _renderer;

  const GenerateReportPdfUseCase({
    required PrepareReportExportUseCase prepare,
    required ReportPdfRenderer renderer,
    ReportExportProjector projector = const ReportExportProjector(),
  }) : _prepare = prepare,
       _renderer = renderer,
       _projector = projector;

  Future<Result<Uint8List>> call(GenerateReportPdfParams params) async {
    final prepared = await _prepare(params.report);
    if (prepared is FailureResult<ReportExportDocument>) {
      return FailureResult(prepared.failure);
    }

    final document = (prepared as Success<ReportExportDocument>).data;
    return _renderer.render(
      document: document,
      table: _projector.project(document),
      labels: params.labels,
    );
  }
}
