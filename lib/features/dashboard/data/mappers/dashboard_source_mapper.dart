import '../../../../core/domain/value_objects/currency_code.dart';
import '../../../../core/domain/value_objects/money.dart';
import '../../domain/entities/dashboard_source.dart';
import '../models/dashboard_source_model.dart';

extension DashboardSourceModelMapper on DashboardSourceModel {
  DashboardSource toEntity() {
    final currency = CurrencyCode.tryParse(baseCurrencyCode);
    if (currency == null) {
      throw const FormatException('Invalid dashboard currency code.');
    }

    return DashboardSource(
      companyId: companyId,
      baseCurrencyFractionDigits: baseCurrencyFractionDigits,
      businessTimezone: businessTimezone,
      businessDate: businessDate,
      todayTrips: todayTrips,
      runningTrips: runningTrips,
      deliveredTrips: deliveredTrips,
      availableVehicles: availableVehicles,
      vehiclesOnTrip: vehiclesOnTrip,
      unpaidInvoices: unpaidInvoices,
      revenue: Money(minorUnits: revenueMinorUnits, currency: currency),
      tripExpenses: Money(
        minorUnits: tripExpensesMinorUnits,
        currency: currency,
      ),
      companyExpenses: Money(
        minorUnits: companyExpensesMinorUnits,
        currency: currency,
      ),
      financialCurrencyMismatchCount: financialCurrencyMismatchCount,
      expensePrecisionLossCount: expensePrecisionLossCount,
      negativeExpenseCount: negativeExpenseCount,
      invalidInvoiceBalanceCount: invalidInvoiceBalanceCount,
    );
  }
}
