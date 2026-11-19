import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/result.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../../domain/entities/report_date_range.dart';
import '../../domain/entities/report_export_kind.dart';
import '../../domain/entities/report_export_labels.dart';
import '../../domain/repositories/report_pdf_delivery_repository.dart';
import '../../domain/usecases/generate_report_pdf_usecase.dart';
import '../../domain/usecases/prepare_report_export_usecase.dart';
import '../../domain/usecases/report_pdf_delivery_usecases.dart';
import 'report_export_state.dart';

/// Isolated orchestration. No report calculations or platform APIs here.
final class ReportExportCubit extends Cubit<ReportExportState> {
  final GenerateReportPdfUseCase _generate;
  final SaveReportPdfUseCase _save;
  final PrintReportPdfUseCase _print;
  final ShareReportPdfUseCase _share;

  int _generation = 0;
  String? _companyId;

  ReportExportCubit({
    required GenerateReportPdfUseCase generate,
    required SaveReportPdfUseCase save,
    required PrintReportPdfUseCase print,
    required ShareReportPdfUseCase share,
  }) : _generate = generate,
       _save = save,
       _print = print,
       _share = share,
       super(const ReportExportIdle());

  bool get isBusy => state is ReportExportBusy;

  Future<void> perform({
    required ReportPdfAction action,
    required CurrentCompanyContext currentCompanyContext,
    required ReportExportKind kind,
    required ReportDateRange dateRange,
    required ReportExportLabels labels,
  }) async {
    if (isBusy || isClosed) return;
    final generation = ++_generation;
    _companyId = currentCompanyContext.companyId;
    emit(ReportExportBusy(action));

    final result = await _generate(
      GenerateReportPdfParams(
        report: PrepareReportExportParams(
          currentCompanyContext: currentCompanyContext,
          kind: kind,
          dateRange: dateRange,
        ),
        labels: labels,
      ),
    );
    if (!_isCurrent(generation, currentCompanyContext.companyId)) return;
    if (result.failureOrNull != null) {
      emit(ReportExportFailed(result.failureOrNull!));
      return;
    }

    final generated = result.dataOrNull!;
    if (action == ReportPdfAction.preview) {
      emit(ReportExportPreviewReady(generated.bytes));
      return;
    }

    final params = ReportPdfDeliveryParams(
      bytes: generated.bytes,
      fileName: generated.fileName,
    );
    final Result<ReportPdfDeliveryOutcome> delivered;
    switch (action) {
      case ReportPdfAction.save:
        delivered = await _save(params);
      case ReportPdfAction.print:
        delivered = await _print(params);
      case ReportPdfAction.share:
        delivered = await _share(params);
      case ReportPdfAction.preview:
        return;
    }
    if (!_isCurrent(generation, currentCompanyContext.companyId)) return;
    if (delivered.failureOrNull != null) {
      emit(ReportExportFailed(delivered.failureOrNull!));
      return;
    }
    emit(ReportExportCompleted(action, delivered.dataOrNull!));
  }

  /// Discard in-flight results when report parameters or tenant change.
  void invalidate() {
    ++_generation;
    _companyId = null;
    if (!isClosed) emit(const ReportExportIdle());
  }

  void clearFeedback() {
    if (!isClosed && !isBusy) emit(const ReportExportIdle());
  }

  bool _isCurrent(int generation, String companyId) =>
      !isClosed && generation == _generation && _companyId == companyId;
}
