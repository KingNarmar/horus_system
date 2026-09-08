import 'package:horus_system/core/domain/value_objects/business_date.dart';
import 'package:horus_system/features/expenses/data/mappers/trip_expense_mapper.dart';
import 'package:horus_system/features/expenses/data/models/trip_expense_model.dart';
import 'package:horus_system/features/expenses/domain/entities/trip_expense_paid_by.dart';
import 'package:horus_system/features/expenses/domain/entities/trip_expense_write_data.dart';
import 'package:test/test.dart';

void main() {
  group('Trip expense business-date mapping', () {
    test('model preserves expense calendar date', () {
      final model = TripExpenseModel.fromMap({
        'id': 'expense-1',
        'company_id': 'company-1',
        'trip_id': 'trip-1',
        'expense_name': 'Toll',
        'amount': 100,
        'paid_by': 'company',
        'expense_date': '2026-09-07',
      });

      expect(
        model.expenseDate,
        BusinessDate(year: 2026, month: 9, day: 7),
      );
      expect(model.toEntity().expenseDate, model.expenseDate);
    });

    test('write data serializes exact expense date', () {
      final data = TripExpenseWriteData(
        companyId: 'company-1',
        tripId: 'trip-1',
        expenseName: 'Toll',
        amount: 100,
        paidBy: TripExpensePaidBy.company,
        expenseDate: BusinessDate(year: 2026, month: 9, day: 7),
      );

      final map = data.toInsertMap();

      expect(map['expense_date'], '2026-09-07');
    });

    test('model rejects timestamp-shaped expense date', () {
      expect(
        () => TripExpenseModel.fromMap({
          'id': 'expense-1',
          'company_id': 'company-1',
          'trip_id': 'trip-1',
          'expense_name': 'Toll',
          'amount': 100,
          'paid_by': 'company',
          'expense_date': '2026-09-07T00:00:00Z',
        }),
        throwsFormatException,
      );
    });
  });
}
