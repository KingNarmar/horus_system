import 'package:horus_system/features/dashboard/data/mappers/dashboard_source_mapper.dart';
import 'package:horus_system/features/dashboard/data/models/dashboard_source_model.dart';
import 'package:test/test.dart';

void main() {
  test('maps dashboard source model to Money-backed Domain source', () {
    final model = DashboardSourceModel.fromMap({
      'company': {
        'company_id': 'company-1',
        'base_currency_code': 'AED',
        'base_currency_fraction_digits': 2,
        'business_timezone': 'Asia/Dubai',
        'business_date': '2026-08-12',
      },
      'metrics': {
        'today_trips': 0,
        'running_trips': 0,
        'delivered_trips': 3,
        'available_vehicles': 2,
        'vehicles_on_trip': 1,
        'unpaid_invoices': 0,
      },
      'financial': {
        'revenue_minor_units': 120000,
        'trip_expenses_minor_units': 980000,
        'company_expenses_minor_units': 751000,
      },
      'validation': {
        'financial_currency_mismatch_count': 0,
        'expense_precision_loss_count': 0,
        'negative_expense_count': 0,
        'invalid_invoice_balance_count': 0,
      },
    });

    final source = model.toEntity();

    expect(source.companyId, 'company-1');
    expect(source.businessDate, DateTime(2026, 8, 12));
    expect(source.revenue.minorUnits, 120000);
    expect(source.revenue.currency.value, 'AED');
    expect(source.tripExpenses.minorUnits, 980000);
    expect(source.companyExpenses.minorUnits, 751000);
    expect(source.deliveredTrips, 3);
    expect(source.availableVehicles, 2);
    expect(source.vehiclesOnTrip, 1);
  });
}
