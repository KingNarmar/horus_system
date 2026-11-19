import 'dart:typed_data';

import '../../../../core/errors/common_failures.dart';
import '../../../../core/utils/result.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../../../company/domain/repositories/company_branding_repository.dart';
import '../entities/report_date_range.dart';
import '../entities/report_export_document.dart';
import '../entities/report_export_kind.dart';
import '../failures/reports_failure_codes.dart';
import 'get_open_invoices_report_usecase.dart';
import 'get_operational_report_usecase.dart';
import 'get_trip_expenses_report_usecase.dart';
import 'get_trip_net_profit_report_usecase.dart';
import 'report_params.dart';

final class PrepareReportExportParams {
  final CurrentCompanyContext currentCompanyContext;
  final ReportExportKind kind;
  final ReportDateRange dateRange;

  const PrepareReportExportParams({
    required this.currentCompanyContext,
    required this.kind,
    required this.dateRange,
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

  const PrepareReportExportUseCase({
    required GetOperationalReportUseCase operational,
    required GetTripExpensesReportUseCase expenses,
    required GetTripNetProfitReportUseCase profit,
    required GetOpenInvoicesReportUseCase invoices,
    required CompanyBrandingRepository branding,
    required DateTime Function() clock,
  }) : _operational = operational,
       _expenses = expenses,
       _profit = profit,
       _invoices = invoices,
       _branding = branding,
       _clock = clock;

  Future<Result<ReportExportDocument>> call(
    PrepareReportExportParams params,
  ) async {
    final context = params.currentCompanyContext;
    if (!params.kind.canView(context.role)) {
      return const FailureResult(
        PermissionFailure(code: ReportsFailureCodes.permissionExport),
      );
    }

    final report = await _loadAuthorizedContent(params);
    if (report is FailureResult<ReportExportContent>) {
      return FailureResult(report.failure);
    }

    final profileResult = await _branding.getProfile(context.companyId);
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
        content: report.dataOrNull!,
      ),
    );
  }

  Future<Result<ReportExportContent>> _loadAuthorizedContent(
    PrepareReportExportParams params,
  ) async {
    final dimension = params.kind.operationalDimension;
    if (dimension != null) {
      final result = await _operational(
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
      ReportExportKind.tripExpenses => (await _expenses(request)).when(
        success: (value) =>
            Success<ReportExportContent>(ReportExportExpensesContent(value)),
        failure: (value) => FailureResult<ReportExportContent>(value),
      ),
      ReportExportKind.tripNetProfit => (await _profit(request)).when(
        success: (value) =>
            Success<ReportExportContent>(ReportExportProfitContent(value)),
        failure: (value) => FailureResult<ReportExportContent>(value),
      ),
      ReportExportKind.openInvoices => (await _invoices(request)).when(
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
