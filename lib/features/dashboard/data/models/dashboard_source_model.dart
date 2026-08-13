import '../constants/dashboard_db_constants.dart';

final class DashboardSourceModel {
  final String companyId;
  final String baseCurrencyCode;
  final int baseCurrencyFractionDigits;
  final String businessTimezone;
  final DateTime businessDate;

  final int todayTrips;
  final int runningTrips;
  final int deliveredTrips;
  final int availableVehicles;
  final int vehiclesOnTrip;
  final int unpaidInvoices;

  final int revenueMinorUnits;
  final int tripExpensesMinorUnits;
  final int companyExpensesMinorUnits;

  final int financialCurrencyMismatchCount;
  final int expensePrecisionLossCount;
  final int negativeExpenseCount;
  final int invalidInvoiceBalanceCount;

  const DashboardSourceModel({
    required this.companyId,
    required this.baseCurrencyCode,
    required this.baseCurrencyFractionDigits,
    required this.businessTimezone,
    required this.businessDate,
    required this.todayTrips,
    required this.runningTrips,
    required this.deliveredTrips,
    required this.availableVehicles,
    required this.vehiclesOnTrip,
    required this.unpaidInvoices,
    required this.revenueMinorUnits,
    required this.tripExpensesMinorUnits,
    required this.companyExpensesMinorUnits,
    required this.financialCurrencyMismatchCount,
    required this.expensePrecisionLossCount,
    required this.negativeExpenseCount,
    required this.invalidInvoiceBalanceCount,
  });

  factory DashboardSourceModel.fromMap(Map<String, dynamic> map) {
    final company = _requiredMap(
      map[DashboardDbConstants.company],
      DashboardDbConstants.company,
    );
    final metrics = _requiredMap(
      map[DashboardDbConstants.metrics],
      DashboardDbConstants.metrics,
    );
    final financial = _requiredMap(
      map[DashboardDbConstants.financial],
      DashboardDbConstants.financial,
    );
    final validation = _requiredMap(
      map[DashboardDbConstants.validation],
      DashboardDbConstants.validation,
    );

    return DashboardSourceModel(
      companyId: _requiredString(
        company[DashboardDbConstants.companyId],
        DashboardDbConstants.companyId,
      ),
      baseCurrencyCode: _requiredString(
        company[DashboardDbConstants.baseCurrencyCode],
        DashboardDbConstants.baseCurrencyCode,
      ),
      baseCurrencyFractionDigits: _requiredInt(
        company[DashboardDbConstants.baseCurrencyFractionDigits],
        DashboardDbConstants.baseCurrencyFractionDigits,
      ),
      businessTimezone: _requiredString(
        company[DashboardDbConstants.businessTimezone],
        DashboardDbConstants.businessTimezone,
      ),
      businessDate: _requiredDate(
        company[DashboardDbConstants.businessDate],
        DashboardDbConstants.businessDate,
      ),
      todayTrips: _requiredInt(
        metrics[DashboardDbConstants.todayTrips],
        DashboardDbConstants.todayTrips,
      ),
      runningTrips: _requiredInt(
        metrics[DashboardDbConstants.runningTrips],
        DashboardDbConstants.runningTrips,
      ),
      deliveredTrips: _requiredInt(
        metrics[DashboardDbConstants.deliveredTrips],
        DashboardDbConstants.deliveredTrips,
      ),
      availableVehicles: _requiredInt(
        metrics[DashboardDbConstants.availableVehicles],
        DashboardDbConstants.availableVehicles,
      ),
      vehiclesOnTrip: _requiredInt(
        metrics[DashboardDbConstants.vehiclesOnTrip],
        DashboardDbConstants.vehiclesOnTrip,
      ),
      unpaidInvoices: _requiredInt(
        metrics[DashboardDbConstants.unpaidInvoices],
        DashboardDbConstants.unpaidInvoices,
      ),
      revenueMinorUnits: _requiredInt(
        financial[DashboardDbConstants.revenueMinorUnits],
        DashboardDbConstants.revenueMinorUnits,
      ),
      tripExpensesMinorUnits: _requiredInt(
        financial[DashboardDbConstants.tripExpensesMinorUnits],
        DashboardDbConstants.tripExpensesMinorUnits,
      ),
      companyExpensesMinorUnits: _requiredInt(
        financial[DashboardDbConstants.companyExpensesMinorUnits],
        DashboardDbConstants.companyExpensesMinorUnits,
      ),
      financialCurrencyMismatchCount: _requiredInt(
        validation[DashboardDbConstants.financialCurrencyMismatchCount],
        DashboardDbConstants.financialCurrencyMismatchCount,
      ),
      expensePrecisionLossCount: _requiredInt(
        validation[DashboardDbConstants.expensePrecisionLossCount],
        DashboardDbConstants.expensePrecisionLossCount,
      ),
      negativeExpenseCount: _requiredInt(
        validation[DashboardDbConstants.negativeExpenseCount],
        DashboardDbConstants.negativeExpenseCount,
      ),
      invalidInvoiceBalanceCount: _requiredInt(
        validation[DashboardDbConstants.invalidInvoiceBalanceCount],
        DashboardDbConstants.invalidInvoiceBalanceCount,
      ),
    );
  }
}

Map<String, dynamic> _requiredMap(Object? value, String field) {
  if (value is! Map) {
    throw FormatException('Invalid dashboard object: $field.');
  }
  return Map<String, dynamic>.from(value);
}

String _requiredString(Object? value, String field) {
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('Invalid dashboard field: $field.');
  }
  return value.trim();
}

int _requiredInt(Object? value, String field) {
  if (value is int) return value;
  if (value is num && value == value.truncate()) return value.toInt();
  throw FormatException('Invalid dashboard integer field: $field.');
}

DateTime _requiredDate(Object? value, String field) {
  final raw = _requiredString(value, field);
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) {
    throw FormatException('Invalid dashboard date: $field.');
  }
  return DateTime(parsed.year, parsed.month, parsed.day);
}
