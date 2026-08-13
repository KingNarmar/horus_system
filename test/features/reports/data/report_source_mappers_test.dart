import 'package:horus_system/features/expenses/domain/entities/trip_expense_paid_by.dart';
import 'package:horus_system/features/reports/data/mappers/report_source_mappers.dart';
import 'package:horus_system/features/reports/data/models/open_invoices_report_source_model.dart';
import 'package:horus_system/features/reports/data/models/trip_expenses_report_source_model.dart';
import 'package:horus_system/features/invoices/domain/entities/invoice_status.dart';
import 'package:test/test.dart';

void main() {
  test('maps expense source with typed paid-by and base currency money', () {
    final model = TripExpensesReportSourceModel.fromMap({
      'company': _company,
      'period': {'from_date': '2026-06-26', 'to_date': '2026-06-26'},
      'validation': {'precision_loss_count': 0, 'negative_amount_count': 0},
      'rows': [
        {
          'expense_id': 'expense-1',
          'expense_date': '2026-06-26',
          'trip_id': 'trip-1',
          'trip_number': 'TR-1',
          'trip_date': '2026-06-26',
          'customer_id': 'customer-1',
          'customer_name': 'Customer',
          'loading_location': 'Dubai',
          'unloading_location': 'Abu Dhabi',
          'loading_order_number': null,
          'waybill_number': null,
          'expense_type_id': 'type-1',
          'expense_name': 'Fuel',
          'paid_by': 'driver_advance',
          'amount_minor_units': 2500,
        },
      ],
    });

    final source = model.toEntity();
    expect(source.rows.single.paidBy, TripExpensePaidBy.driverAdvance);
    expect(source.rows.single.amount.minorUnits, 2500);
    expect(source.rows.single.amount.currency.value, 'AED');
    expect(source.metadata.fromDate, DateTime(2026, 6, 26));
  });

  test('maps paid invoice source without classifying it as open in Data', () {
    final model = OpenInvoicesReportSourceModel.fromMap({
      'company': _company,
      'period': {'from_date': null, 'to_date': null},
      'validation': {
        'invoice_currency_mismatch_count': 0,
        'payment_currency_mismatch_count': 0,
        'invalid_invoice_amount_count': 0,
        'invalid_payment_amount_count': 0,
        'missing_issue_date_count': 0,
      },
      'invoices': [
        {
          'invoice_id': 'invoice-1',
          'invoice_number': 'INV-1',
          'customer_id': 'customer-1',
          'customer_name': 'Customer snapshot',
          'status': 'paid',
          'currency_code': 'AED',
          'total_minor_units': 120000,
          'issue_date': '2026-07-01',
          'due_date': '2026-07-31',
          'issued_at': '2026-07-01T09:00:00+04:00',
        },
      ],
      'payments': [
        {
          'payment_id': 'payment-1',
          'invoice_id': 'invoice-1',
          'currency_code': 'AED',
          'amount_minor_units': 120000,
          'payment_date': '2026-07-10',
          'created_at': '2026-07-10T10:00:00+04:00',
        },
      ],
    });

    final source = model.toEntity();
    expect(source.invoices.single.status, InvoiceStatus.paid);
    expect(source.invoices.single.customerName, 'Customer snapshot');
    expect(source.payments.single.amount.minorUnits, 120000);
  });

  test('rejects unknown report enum values instead of silently defaulting', () {
    final model = TripExpensesReportSourceModel.fromMap({
      'company': _company,
      'period': {'from_date': null, 'to_date': null},
      'validation': {'precision_loss_count': 0, 'negative_amount_count': 0},
      'rows': [
        {
          'expense_id': 'expense-1',
          'expense_date': '2026-06-26',
          'trip_id': 'trip-1',
          'trip_number': null,
          'trip_date': '2026-06-26',
          'customer_id': 'customer-1',
          'customer_name': 'Customer',
          'loading_location': 'Dubai',
          'unloading_location': 'Abu Dhabi',
          'loading_order_number': null,
          'waybill_number': null,
          'expense_type_id': null,
          'expense_name': 'Fuel',
          'paid_by': 'unknown_value',
          'amount_minor_units': 2500,
        },
      ],
    });

    expect(model.toEntity, throwsFormatException);
  });
}

const _company = {
  'company_id': 'company-1',
  'base_currency_code': 'AED',
  'base_currency_fraction_digits': 2,
  'business_timezone': 'Asia/Dubai',
  'business_date': '2026-08-13',
};
