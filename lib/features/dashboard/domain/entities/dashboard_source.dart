import '../../../../core/domain/value_objects/money.dart';

final class DashboardSource {
  final String companyId;
  final int baseCurrencyFractionDigits;
  final String businessTimezone;
  final DateTime businessDate;

  final int todayTrips;
  final int runningTrips;
  final int deliveredTrips;
  final int availableVehicles;
  final int vehiclesOnTrip;
  final int unpaidInvoices;

  final Money revenue;
  final Money tripExpenses;
  final Money companyExpenses;

  final int financialCurrencyMismatchCount;
  final int expensePrecisionLossCount;
  final int negativeExpenseCount;
  final int invalidInvoiceBalanceCount;

  const DashboardSource({
    required this.companyId,
    required this.baseCurrencyFractionDigits,
    required this.businessTimezone,
    required this.businessDate,
    required this.todayTrips,
    required this.runningTrips,
    required this.deliveredTrips,
    required this.availableVehicles,
    required this.vehiclesOnTrip,
    required this.unpaidInvoices,
    required this.revenue,
    required this.tripExpenses,
    required this.companyExpenses,
    required this.financialCurrencyMismatchCount,
    required this.expensePrecisionLossCount,
    required this.negativeExpenseCount,
    required this.invalidInvoiceBalanceCount,
  });
}
