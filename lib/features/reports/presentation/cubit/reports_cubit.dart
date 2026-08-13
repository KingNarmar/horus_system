import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/result.dart';

import '../../../company/domain/entities/current_company_context.dart';
import '../../domain/entities/report_date_range.dart';
import '../../domain/usecases/get_open_invoices_report_usecase.dart';
import '../../domain/usecases/get_operational_report_usecase.dart';
import '../../domain/usecases/get_trip_expenses_report_usecase.dart';
import '../../domain/usecases/get_trip_net_profit_report_usecase.dart';
import '../../domain/usecases/report_params.dart';
import 'report_type.dart';
import 'reports_state.dart';

final class ReportsCubit extends Cubit<ReportsState> {
  final GetOperationalReportUseCase _getOperationalReport;
  final GetTripExpensesReportUseCase _getTripExpensesReport;
  final GetTripNetProfitReportUseCase _getTripNetProfitReport;
  final GetOpenInvoicesReportUseCase _getOpenInvoicesReport;

  CurrentCompanyContext? _currentContext;
  int _requestId = 0;

  ReportsCubit({
    required GetOperationalReportUseCase getOperationalReport,
    required GetTripExpensesReportUseCase getTripExpensesReport,
    required GetTripNetProfitReportUseCase getTripNetProfitReport,
    required GetOpenInvoicesReportUseCase getOpenInvoicesReport,
  }) : _getOperationalReport = getOperationalReport,
       _getTripExpensesReport = getTripExpensesReport,
       _getTripNetProfitReport = getTripNetProfitReport,
       _getOpenInvoicesReport = getOpenInvoicesReport,
       super(const ReportsInitial());

  Future<void> load({
    required CurrentCompanyContext currentCompanyContext,
    ReportType? reportType,
    ReportDateRange? dateRange,
  }) async {
    _currentContext = currentCompanyContext;
    final selectedType = reportType ?? state.reportType;
    final selectedRange = (dateRange ?? state.dateRange).normalized();
    final requestId = ++_requestId;
    emit(ReportsLoading(reportType: selectedType, dateRange: selectedRange));

    final content = await _loadContent(
      context: currentCompanyContext,
      reportType: selectedType,
      dateRange: selectedRange,
    );
    if (!_isCurrentRequest(requestId, currentCompanyContext)) return;

    content.when(
      success: (value) => emit(
        ReportsLoaded(
          reportType: selectedType,
          dateRange: selectedRange,
          content: value,
        ),
      ),
      failure: (failure) => emit(
        ReportsLoadFailure(
          reportType: selectedType,
          dateRange: selectedRange,
          failure: failure,
        ),
      ),
    );
  }

  Future<Result<ReportsContent>> _loadContent({
    required CurrentCompanyContext context,
    required ReportType reportType,
    required ReportDateRange dateRange,
  }) async {
    final dimension = reportType.operationalDimension;
    if (dimension != null) {
      final result = await _getOperationalReport(
        OperationalReportParams(
          currentCompanyContext: context,
          dimension: dimension,
          dateRange: dateRange,
        ),
      );
      return result.when(
        success: (report) => Success<ReportsContent>(
          OperationalReportsContent(report),
        ),
        failure: (failure) => FailureResult<ReportsContent>(failure),
      );
    }

    final params = ReportParams(
      currentCompanyContext: context,
      dateRange: dateRange,
    );
    return switch (reportType) {
      ReportType.tripExpenses => (await _getTripExpensesReport(params)).when(
        success: (report) => Success<ReportsContent>(
          TripExpensesReportsContent(report),
        ),
        failure: (failure) => FailureResult<ReportsContent>(failure),
      ),
      ReportType.tripNetProfit => (await _getTripNetProfitReport(params)).when(
        success: (report) => Success<ReportsContent>(
          TripNetProfitReportsContent(report),
        ),
        failure: (failure) => FailureResult<ReportsContent>(failure),
      ),
      ReportType.openInvoices => (await _getOpenInvoicesReport(params)).when(
        success: (report) => Success<ReportsContent>(
          OpenInvoicesReportsContent(report),
        ),
        failure: (failure) => FailureResult<ReportsContent>(failure),
      ),
      ReportType.dailyTrips ||
      ReportType.tripsByCustomer ||
      ReportType.tripsByDriver ||
      ReportType.tripsByTractorHead ||
      ReportType.tripsByTrailer => throw StateError('Handled above.'),
    };
  }

  bool _isCurrentRequest(int requestId, CurrentCompanyContext requestContext) {
    final current = _currentContext;
    return !isClosed &&
        requestId == _requestId &&
        current?.companyId == requestContext.companyId &&
        current?.role == requestContext.role;
  }
}
