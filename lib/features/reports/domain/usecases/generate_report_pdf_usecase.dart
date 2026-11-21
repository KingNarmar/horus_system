import '../../../../core/utils/result.dart';
import '../entities/generated_report_pdf.dart';
import '../entities/report_export_document.dart';
import '../failures/report_export_cancelled_failure.dart';
import '../entities/report_export_labels.dart';
import '../entities/report_export_progress.dart';
import '../policies/report_pdf_page_layout_policy.dart';
import '../services/report_export_projector.dart';
import '../services/report_pdf_renderer.dart';
import '../policies/report_export_file_name_policy.dart';
import 'prepare_report_export_usecase.dart';

final class GenerateReportPdfParams {
  final PrepareReportExportParams report;
  final ReportExportLabels labels;

  const GenerateReportPdfParams({required this.report, required this.labels});
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

  Future<Result<GeneratedReportPdf>> call(
    GenerateReportPdfParams params,
  ) async {
    final prepared = await _prepare(params.report);
    if (params.report.cancellation?.isCancelled ?? false) {
      return const FailureResult(ReportExportCancelledFailure());
    }
    if (prepared is FailureResult<ReportExportDocument>) {
      return FailureResult(prepared.failure);
    }

    final document = (prepared as Success<ReportExportDocument>).data;
    params.report.onProgress?.call(
      const ReportExportProgress(stage: ReportExportStage.renderingPdf),
    );
    final table = _projector.project(document);
    final pageLayout = ReportPdfPageLayoutPolicy.forColumns(table.columns);
    final rendered = await _renderer.render(
      document: document,
      table: table,
      labels: params.labels,
      pageLayout: pageLayout,
    );
    // An in-flight render cannot be interrupted; discard its output instead.
    if (params.report.cancellation?.isCancelled ?? false) {
      return const FailureResult(ReportExportCancelledFailure());
    }
    if (rendered.failureOrNull != null) {
      return FailureResult(rendered.failureOrNull!);
    }
    return Success(
      GeneratedReportPdf(
        bytes: rendered.dataOrNull!,
        pageLayout: pageLayout,
        fileName: ReportExportFileNamePolicy.pdf(
          kind: document.kind,
          generatedAtUtc: document.generatedAtUtc,
        ),
      ),
    );
  }
}
