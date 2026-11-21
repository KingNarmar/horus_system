import 'dart:typed_data';

import '../../../../core/errors/common_failures.dart';
import '../../../../core/utils/result.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../../../company/domain/repositories/company_branding_repository.dart';
import '../entities/report_date_range.dart';
import '../entities/report_export_cancellation.dart';
import '../entities/report_export_document.dart';
import '../entities/report_export_kind.dart';
import '../entities/report_export_progress.dart';
import '../failures/reports_failure_codes.dart';
import '../failures/report_export_cancelled_failure.dart';
import '../repositories/report_export_sources_factory.dart';
import 'get_open_invoices_report_usecase.dart';
import 'get_operational_report_usecase.dart';
import 'get_trip_expenses_report_usecase.dart';
import 'get_trip_net_profit_report_usecase.dart';
import 'report_params.dart';

final class PrepareReportExportParams {
  final CurrentCompanyContext currentCompanyContext;
  final ReportExportKind kind;
  final ReportDateRange dateRange;
  final ReportExportCancellation? cancellation;
  final ReportExportProgressCallback? onProgress;

  const PrepareReportExportParams({
    required this.currentCompanyContext,
    required this.kind,
    required this.dateRange,
    this.cancellation,
    this.onProgress,
  });
}

/// Re-reads the authoritative report under the current role before exporting.
/// Does not trust a previously rendered report or calculate financial values.
final class PrepareReportExportUseCase {
  final GetOperationalReportUseCase _operational;
  final GetTripExpensesReportUseCase _expenses;
  final GetTripNetProfitReportUseCase _profit;
  final GetOpenInvoicesReportUseCase _invoices;
  final CompanyBrandingRepository _branding;
  final DateTime Function() _clock;
  final ReportExportSourcesFactory? _exportSourcesFactory;

  const PrepareReportExportUseCase({
    required GetOperationalReportUseCase operational,
    required GetTripExpensesReportUseCase expenses,
    required GetTripNetProfitReportUseCase profit,
    required GetOpenInvoicesReportUseCase invoices,
    required CompanyBrandingRepository branding,
    required DateTime Function() clock,
    ReportExportSourcesFactory? exportSourcesFactory,
  }) : _operational = operational,
       _expenses = expenses,
       _profit = profit,
       _invoices = invoices,
       _branding = branding,
       _clock = clock,
       _exportSourcesFactory = exportSourcesFactory;

  Future<Result<ReportExportDocument>> call(
    PrepareReportExportParams params,
  ) async {
    if (params.cancellation?.isCancelled ?? false) {
      return const FailureResult(ReportExportCancelledFailure());
    }
    final context = params.currentCompanyContext;
    if (!params.kind.canView(context.role)) {
      return const FailureResult(
        PermissionFailure(code: ReportsFailureCodes.permissionExport),
      );
    }

    params.onProgress?.call(
      const ReportExportProgress(stage: ReportExportStage.readingSource),
    );
    final report = await _loadAuthorizedContent(params);
    if (params.cancellation?.isCancelled ?? false) {
      return const FailureResult(ReportExportCancelledFailure());
    }
    if (report is FailureResult<ReportExportContent>) {
      return FailureResult(report.failure);
    }
    final content = report.dataOrNull!;
    if (!content.hasExportableRows) {
      return const FailureResult(
        NotFoundFailure(code: ReportsFailureCodes.exportNoData),
      );
    }

    params.onProgress?.call(
      const ReportExportProgress(stage: ReportExportStage.loadingBranding),
    );
    final profileResult = await _branding.getProfile(context.companyId);
    if (params.cancellation?.isCancelled ?? false) {
      return const FailureResult(ReportExportCancelledFailure());
    }
    if (profileResult.failureOrNull != null) {
      return FailureResult(profileResult.failureOrNull!);
    }
    final profile = profileResult.dataOrNull!;
    if (profile.companyId != context.companyId) {
      return const FailureResult(
        PermissionFailure(code: ReportsFailureCodes.permissionExport),
      );
    }

    Uint8List? logoBytes;
    final path = profile.logoPath;
    if (path != null && path.isNotEmpty) {
      final logo = await _branding.downloadLogo(
        companyId: context.companyId,
        storagePath: path,
      );
      if (params.cancellation?.isCancelled ?? false) {
        return const FailureResult(ReportExportCancelledFailure());
      }
      if (logo.failureOrNull != null) {
        return FailureResult(logo.failureOrNull!);
      }
      logoBytes = logo.dataOrNull;
    }

    return Success(
      ReportExportDocument(
        companyId: context.companyId,
        companyName: profile.name,
        logoBytes: logoBytes,
        kind: params.kind,
        dateRange: params.dateRange.normalized(),
        generatedAtUtc: _clock().toUtc(),
        content: content,
      ),
    );
  }

  Future<Result<ReportExportContent>> _loadAuthorizedContent(
    PrepareReportExportParams params,
  ) async {
    final source = _exportSourcesFactory?.call(
      cancellation: params.cancellation ?? ReportExportCancellation(),
      onProgress: params.onProgress,
    );
    final operational = source == null
        ? _operational
        : GetOperationalReportUseCase(repository: source);
    final expenses = source == null
        ? _expenses
        : GetTripExpensesReportUseCase(source);
    final profit = source == null
        ? _profit
        : GetTripNetProfitReportUseCase(repository: source);
    final invoices = source == null
        ? _invoices
        : GetOpenInvoicesReportUseCase(repository: source);

    final dimension = params.kind.operationalDimension;
    if (dimension != null) {
      final result = await operational(
        OperationalReportParams(
          currentCompanyContext: params.currentCompanyContext,
          dimension: dimension,
          dateRange: params.dateRange,
        ),
      );
      return result.when(
        success: (value) =>
            Success<ReportExportContent>(ReportExportOperationalContent(value)),
        failure: (value) => FailureResult<ReportExportContent>(value),
      );
    }

    final request = ReportParams(
      currentCompanyContext: params.currentCompanyContext,
      dateRange: params.dateRange,
    );
    return switch (params.kind) {
      ReportExportKind.tripExpenses => (await expenses(request)).when(
        success: (value) =>
            Success<ReportExportContent>(ReportExportExpensesContent(value)),
        failure: (value) => FailureResult<ReportExportContent>(value),
      ),
      ReportExportKind.tripNetProfit => (await profit(request)).when(
        success: (value) =>
            Success<ReportExportContent>(ReportExportProfitContent(value)),
        failure: (value) => FailureResult<ReportExportContent>(value),
      ),
      ReportExportKind.openInvoices => (await invoices(request)).when(
        success: (value) =>
            Success<ReportExportContent>(ReportExportInvoicesContent(value)),
        failure: (value) => FailureResult<ReportExportContent>(value),
      ),
      _ => const FailureResult<ReportExportContent>(
        ConflictFailure(code: ReportsFailureCodes.conflictSourceInvalid),
      ),
    };
  }
}
