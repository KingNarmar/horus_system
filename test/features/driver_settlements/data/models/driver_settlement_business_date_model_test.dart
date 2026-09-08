import 'package:horus_system/core/domain/value_objects/business_date.dart';
import 'package:horus_system/features/driver_settlements/data/models/driver_settlement_model.dart';
import 'package:test/test.dart';

void main() {
  group('Driver settlement business-date parsing', () {
    Map<String, dynamic> baseMap({
      Object? periodStart = '2026-09-01',
      Object? periodEnd = '2026-09-30',
    }) {
      return {
        'id': 'settlement-1',
        'company_id': 'company-1',
        'driver_id': 'driver-1',
        'period_start': periodStart,
        'period_end': periodEnd,
        'opening_driver_balance': 0,
        'advances_total': 0,
        'driver_paid_trip_expenses_total': 0,
        'returned_cash_total': 0,
        'deductions_total': 0,
        'settlement_deductions_total': 0,
        'gross_salary': 0,
        'salary_deductions_total': 0,
        'balance_deduction_applied': 0,
        'net_salary_payable': 0,
        'closing_driver_balance': 0,
        'status': 'draft',
      };
    }

    test('model preserves settlement period calendar dates', () {
      final model = DriverSettlementModel.fromMap(baseMap());

      expect(
        model.periodStart,
        BusinessDate(year: 2026, month: 9, day: 1),
      );
      expect(
        model.periodEnd,
        BusinessDate(year: 2026, month: 9, day: 30),
      );
    });

    test('model rejects timestamp-shaped settlement period dates', () {
      expect(
        () => DriverSettlementModel.fromMap(
          baseMap(periodStart: '2026-09-01T00:00:00Z'),
        ),
        throwsFormatException,
      );
      expect(
        () => DriverSettlementModel.fromMap(
          baseMap(periodEnd: '2026-09-30T00:00:00Z'),
        ),
        throwsFormatException,
      );
    });
  });
}
