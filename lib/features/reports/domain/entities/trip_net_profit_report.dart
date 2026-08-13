import '../../../../core/domain/value_objects/money.dart';
import '../../../trips/domain/entities/trip_status.dart';
import 'report_source_metadata.dart';

final class TripNetProfitSourceTrip {
  final String tripId;
  final String? tripNumber;
  final DateTime operationalDate;
  final TripStatus status;
  final String customerId;
  final String customerName;
  final String? driverId;
  final String? driverName;
  final String? tractorHeadId;
  final String? tractorHeadPlateNumber;
  final String? trailerId;
  final String? trailerPlateNumber;
  final String loadingLocation;
  final String unloadingLocation;
  final String? loadingOrderNumber;
  final String? waybillNumber;
  final Money freight;

  const TripNetProfitSourceTrip({
    required this.tripId,
    required this.tripNumber,
    required this.operationalDate,
    required this.status,
    required this.customerId,
    required this.customerName,
    required this.driverId,
    required this.driverName,
    required this.tractorHeadId,
    required this.tractorHeadPlateNumber,
    required this.trailerId,
    required this.trailerPlateNumber,
    required this.loadingLocation,
    required this.unloadingLocation,
    required this.loadingOrderNumber,
    required this.waybillNumber,
    required this.freight,
  });
}

final class TripNetProfitSourceExpense {
  final String expenseId;
  final String tripId;
  final Money amount;

  const TripNetProfitSourceExpense({
    required this.expenseId,
    required this.tripId,
    required this.amount,
  });
}

final class TripNetProfitReportSource {
  final ReportSourceMetadata metadata;
  final int freightPrecisionLossCount;
  final int negativeFreightCount;
  final int expensePrecisionLossCount;
  final int negativeExpenseCount;
  final List<TripNetProfitSourceTrip> trips;
  final List<TripNetProfitSourceExpense> expenses;

  TripNetProfitReportSource({
    required this.metadata,
    required this.freightPrecisionLossCount,
    required this.negativeFreightCount,
    required this.expensePrecisionLossCount,
    required this.negativeExpenseCount,
    required List<TripNetProfitSourceTrip> trips,
    required List<TripNetProfitSourceExpense> expenses,
  }) : trips = List.unmodifiable(trips),
       expenses = List.unmodifiable(expenses);
}

final class TripNetProfitReportRow {
  final TripNetProfitSourceTrip trip;
  final Money totalExpenses;
  final Money netProfit;

  const TripNetProfitReportRow({
    required this.trip,
    required this.totalExpenses,
    required this.netProfit,
  });
}

final class TripNetProfitReport {
  final ReportSourceMetadata metadata;
  final List<TripNetProfitReportRow> rows;
  final Money totalFreight;
  final Money totalExpenses;
  final Money totalNetProfit;

  TripNetProfitReport({
    required this.metadata,
    required List<TripNetProfitReportRow> rows,
    required this.totalFreight,
    required this.totalExpenses,
    required this.totalNetProfit,
  }) : rows = List.unmodifiable(rows);
}
