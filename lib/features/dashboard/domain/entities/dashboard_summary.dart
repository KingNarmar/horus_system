import '../../../../core/domain/value_objects/money.dart';

final class DashboardSummary {
  final DateTime businessDate;
  final int baseCurrencyFractionDigits;

  final int todayTrips;
  final int runningTrips;
  final int deliveredTrips;
  final int availableVehicles;
  final int vehiclesOnTrip;
  final int unpaidInvoices;

  final Money totalRevenue;
  final Money totalExpenses;
  final Money netProfit;

  const DashboardSummary({
    required this.businessDate,
    required this.baseCurrencyFractionDigits,
    required this.todayTrips,
    required this.runningTrips,
    required this.deliveredTrips,
    required this.availableVehicles,
    required this.vehiclesOnTrip,
    required this.unpaidInvoices,
    required this.totalRevenue,
    required this.totalExpenses,
    required this.netProfit,
  });
}
