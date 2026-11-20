import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/result.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../../domain/entities/generated_report_pdf.dart';
import '../../domain/entities/report_date_range.dart';
import '../../domain/entities/report_export_cancellation.dart';
import '../../domain/entities/report_export_kind.dart';
import '../../domain/entities/report_export_labels.dart';
import '../../domain/repositories/report_pdf_delivery_repository.dart';
import '../../domain/usecases/generate_report_pdf_usecase.dart';
import '../../domain/usecases/prepare_report_export_usecase.dart';
import '../../domain/usecases/reauthorize_report_pdf_print_usecase.dart';
import '../../domain/usecases/report_pdf_delivery_usecases.dart';
import 'report_export_state.dart';

/// Isolated export orchestration; native printing remains in the Data adapter.
final class ReportExportCubit extends Cubit<ReportExportState> {
  final GenerateReportPdfUseCase _generate;
  final ReauthorizeReportPdfPrintUseCase _reauthorizePrint;
  final SaveReportPdfUseCase _save;
  final PrintReportPdfUseCase _print;
  final ShareReportPdfUseCase _share;

  int _generation = 0;
  String? _companyId;
  ReportExportCancellation? _activeCancellation;
  _PendingPrint? _pendingPrint;

  ReportExportCubit({
    required GenerateReportPdfUseCase generate,
    required ReauthorizeReportPdfPrintUseCase reauthorizePrint,
    required SaveReportPdfUseCase save,
    required PrintReportPdfUseCase print,
    required ShareReportPdfUseCase share,
  }) : _generate = generate,
       _reauthorizePrint = reauthorizePrint,
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
    _pendingPrint = null;
    final generation = ++_generation;
    _activeCancellation?.cancel();
    final cancellation = ReportExportCancellation();
    _activeCancellation = cancellation;
    _companyId = currentCompanyContext.companyId;
    emit(ReportExportBusy(action));

    final result = await _generate(
      GenerateReportPdfParams(
        report: PrepareReportExportParams(
          currentCompanyContext: currentCompanyContext,
          kind: kind,
          dateRange: dateRange,
          cancellation: cancellation,
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
    if (action == ReportPdfAction.print) {
      _pendingPrint = _PendingPrint(
        document: generated,
        companyContext: currentCompanyContext,
        kind: kind,
        dateRange: dateRange,
      );
      emit(ReportExportPrintPreviewReady(generated));
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
      case ReportPdfAction.share:
        delivered = await _share(params);
      case ReportPdfAction.preview:
      case ReportPdfAction.print:
        return;
    }
    _finishDelivery(
      generation: generation,
      companyId: currentCompanyContext.companyId,
      action: action,
      result: delivered,
    );
  }

  /// The printer receives exactly the bytes shown in the confirmation dialog.
  /// Re-read through authorized Domain use cases before releasing these bytes.
  Future<void> confirmPrint({
    required CurrentCompanyContext currentCompanyContext,
  }) async {
    if (isClosed || isBusy || state is! ReportExportPrintPreviewReady) return;
    final pending = _pendingPrint;
    if (pending == null) return;
    if (pending.companyContext.companyId != currentCompanyContext.companyId ||
        pending.companyContext.role != currentCompanyContext.role ||
        _companyId != currentCompanyContext.companyId) {
      invalidate();
      return;
    }

    _pendingPrint = null;
    final generation = ++_generation;
    _activeCancellation?.cancel();
    final cancellation = ReportExportCancellation();
    _activeCancellation = cancellation;
    emit(const ReportExportBusy(ReportPdfAction.print));

    final authorized = await _reauthorizePrint(
      PrepareReportExportParams(
        currentCompanyContext: currentCompanyContext,
        kind: pending.kind,
        dateRange: pending.dateRange,
        cancellation: cancellation,
      ),
    );
    if (!_isCurrent(generation, currentCompanyContext.companyId)) return;
    final failure = authorized.failureOrNull;
    if (failure != null) {
      emit(ReportExportFailed(failure));
      return;
    }
    final document = pending.document;
    final delivered = await _print(
      ReportPdfDeliveryParams(
        bytes: document.bytes,
        fileName: document.fileName,
        pageLayout: document.pageLayout,
      ),
    );
    _finishDelivery(
      generation: generation,
      companyId: currentCompanyContext.companyId,
      action: ReportPdfAction.print,
      result: delivered,
    );
  }

  void _finishDelivery({
    required int generation,
    required String companyId,
    required ReportPdfAction action,
    required Result<ReportPdfDeliveryOutcome> result,
  }) {
    if (!_isCurrent(generation, companyId)) return;
    final failure = result.failureOrNull;
    if (failure != null) {
      emit(ReportExportFailed(failure));
      return;
    }
    emit(ReportExportCompleted(action, result.dataOrNull!));
  }

  void cancelPrintPreview() {
    if (isClosed || state is! ReportExportPrintPreviewReady) return;
    _pendingPrint = null;
    emit(const ReportExportIdle());
  }

  /// Discard stale previews and in-flight work when filters or tenant change.
  void invalidate() {
    _pendingPrint = null;
    _activeCancellation?.cancel();
    _activeCancellation = null;
    ++_generation;
    _companyId = null;
    if (!isClosed) emit(const ReportExportIdle());
  }

  @override
  Future<void> close() {
    _pendingPrint = null;
    _activeCancellation?.cancel();
    _activeCancellation = null;
    ++_generation;
    return super.close();
  }

  void clearFeedback() {
    if (!isClosed &&
        !isBusy &&
        state is! ReportExportPrintPreviewReady) {
      emit(const ReportExportIdle());
    }
  }

  bool _isCurrent(int generation, String companyId) =>
      !isClosed && generation == _generation && _companyId == companyId;
}

final class _PendingPrint {
  final GeneratedReportPdf document;
  final CurrentCompanyContext companyContext;
  final ReportExportKind kind;
  final ReportDateRange dateRange;

  const _PendingPrint({
    required this.document,
    required this.companyContext,
    required this.kind,
    required this.dateRange,
  });
}
