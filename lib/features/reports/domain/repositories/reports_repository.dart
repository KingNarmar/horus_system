import '../../../../core/utils/result.dart';
import '../entities/open_invoices_report.dart';
import '../entities/operational_trip_report.dart';
import '../entities/trip_expenses_report.dart';
import '../entities/trip_net_profit_report.dart';

abstract interface class ReportsRepository {
  Future<Result<OperationalTripReportSource>> getOperationalTripSource({
    required String companyId,
    required DateTime? fromDate,
    required DateTime? toDate,
  });

  Future<Result<TripExpensesReportSource>> getTripExpensesSource({
    required String companyId,
    required DateTime? fromDate,
    required DateTime? toDate,
  });

  Future<Result<TripNetProfitReportSource>> getTripNetProfitSource({
    required String companyId,
    required DateTime? fromDate,
    required DateTime? toDate,
  });

  Future<Result<OpenInvoicesReportSource>> getOpenInvoicesSource({
    required String companyId,
    required DateTime? fromDate,
    required DateTime? toDate,
  });
}
