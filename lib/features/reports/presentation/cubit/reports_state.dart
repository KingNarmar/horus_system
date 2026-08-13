import '../../../../core/errors/failure.dart';
import '../../domain/entities/open_invoices_report.dart';
import '../../domain/entities/operational_trip_report.dart';
import '../../domain/entities/report_date_range.dart';
import '../../domain/entities/trip_expenses_report.dart';
import '../../domain/entities/trip_net_profit_report.dart';
import 'report_type.dart';

sealed class ReportsContent {
  const ReportsContent();
}

final class OperationalReportsContent extends ReportsContent {
  final OperationalTripReport report;
  const OperationalReportsContent(this.report);
}

final class TripExpensesReportsContent extends ReportsContent {
  final TripExpensesReport report;
  const TripExpensesReportsContent(this.report);
}

final class TripNetProfitReportsContent extends ReportsContent {
  final TripNetProfitReport report;
  const TripNetProfitReportsContent(this.report);
}

final class OpenInvoicesReportsContent extends ReportsContent {
  final OpenInvoicesReport report;
  const OpenInvoicesReportsContent(this.report);
}

sealed class ReportsState {
  final ReportType reportType;
  final ReportDateRange dateRange;

  const ReportsState({required this.reportType, required this.dateRange});
}

final class ReportsInitial extends ReportsState {
  const ReportsInitial({
    super.reportType = ReportType.dailyTrips,
    super.dateRange = const ReportDateRange(),
  });
}

final class ReportsLoading extends ReportsState {
  const ReportsLoading({required super.reportType, required super.dateRange});
}

final class ReportsLoaded extends ReportsState {
  final ReportsContent content;

  const ReportsLoaded({
    required super.reportType,
    required super.dateRange,
    required this.content,
  });
}

final class ReportsLoadFailure extends ReportsState {
  final Failure failure;

  const ReportsLoadFailure({
    required super.reportType,
    required super.dateRange,
    required this.failure,
  });
}
