import 'package:horus_system/features/customer_statements/data/models/customer_statement_source_model.dart';
import 'package:test/test.dart';

void main() {
  test('parses statement JSON contract including empty arrays', () {
    final model = CustomerStatementSourceModel.fromMap({
      'company': {
        'company_id': 'company-1',
        'base_currency_code': 'AED',
        'base_currency_fraction_digits': 2,
        'business_timezone': 'Asia/Dubai',
      },
      'customer': {
        'customer_id': 'customer-1',
        'customer_name': 'Customer',
        'is_active': true,
      },
      'period': {'from_date': null, 'to_date': '2026-08-10'},
      'opening': {'invoices': [], 'payments': []},
      'movements': [],
    });

    expect(model.companyId, 'company-1');
    expect(model.fromDate, isNull);
    expect(model.toDate, DateTime(2026, 8, 10));
    expect(model.movements, isEmpty);
  });

  test('rejects missing customer object', () {
    expect(
      () => CustomerStatementSourceModel.fromMap({
        'company': {
          'company_id': 'company-1',
          'base_currency_code': 'AED',
          'base_currency_fraction_digits': 2,
          'business_timezone': 'Asia/Dubai',
        },
        'period': {'from_date': null, 'to_date': null},
        'opening': {'invoices': [], 'payments': []},
        'movements': [],
      }),
      throwsFormatException,
    );
  });

  test('rejects fractional minor units instead of truncating', () {
    expect(
      () => CustomerStatementSourceModel.fromMap({
        'company': {
          'company_id': 'company-1',
          'base_currency_code': 'AED',
          'base_currency_fraction_digits': 2,
          'business_timezone': 'Asia/Dubai',
        },
        'customer': {
          'customer_id': 'customer-1',
          'customer_name': 'Customer',
          'is_active': true,
        },
        'period': {'from_date': null, 'to_date': null},
        'opening': {
          'invoices': [
            {'currency_code': 'AED', 'total_minor_units': 1.5},
          ],
          'payments': [],
        },
        'movements': [],
      }),
      throwsFormatException,
    );
  });
}
