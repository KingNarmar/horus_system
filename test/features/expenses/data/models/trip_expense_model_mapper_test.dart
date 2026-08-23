import 'package:horus_system/core/data/constants/db_common_fields.dart';
import 'package:horus_system/features/expenses/data/constants/trip_expense_db_fields.dart';
import 'package:horus_system/features/expenses/data/mappers/trip_expense_mapper.dart';
import 'package:horus_system/features/expenses/data/models/trip_expense_model.dart';
import 'package:horus_system/features/expenses/domain/entities/trip_expense_paid_by.dart';
import 'package:horus_system/features/expenses/domain/entities/trip_expense_write_data.dart';
import 'package:test/test.dart';

void main() {
  group('Trip Expenses database constants', () {
    test('preserve table, lookup, linked-trip, and select identifiers', () {
      expect(TripExpenseDbFields.tableName, 'trip_expenses');
      expect(TripExpenseTypeLookupDbFields.tableName, 'expense_types');
      expect(TripExpenseLinkedTripDbFields.tableName, 'trips');
      expect(TripExpenseLinkedTripDbFields.totalExpenses, 'total_expenses');
      expect(TripExpenseTypeLookupDbFields.lookupColumns, 'id, name');
      expect(
        TripExpenseDbFields.allColumns,
        contains('expense_types!trip_expenses_company_type_fk(name)'),
      );
    });
  });

  group('TripExpenseModel', () {
    test('parses persistence values, numeric strings, dates, and relation', () {
      final model = TripExpenseModel.fromMap({
        'id': 'expense-1',
        'company_id': 'company-1',
        'trip_id': 'trip-1',
        'expense_type_id': 'type-1',
        'expense_name': 'Fuel',
        'amount': '125.75',
        'paid_by': 'driver_cash',
        'expense_date': '2026-08-20',
        'notes': 'diesel',
        'expense_types': {'name': 'Fuel Type'},
        'created_at': '2026-08-20T08:00:00.000Z',
        'updated_at': '2026-08-20T09:00:00.000Z',
      });

      expect(model.id, 'expense-1');
      expect(model.companyId, 'company-1');
      expect(model.tripId, 'trip-1');
      expect(model.expenseTypeId, 'type-1');
      expect(model.expenseName, 'Fuel');
      expect(model.amount, 125.75);
      expect(model.paidBy, 'driver_cash');
      expect(model.expenseDate, DateTime.parse('2026-08-20'));
      expect(model.notes, 'diesel');
      expect(model.expenseTypeName, 'Fuel Type');
      expect(model.createdAt, DateTime.parse('2026-08-20T08:00:00.000Z'));
      expect(model.updatedAt, DateTime.parse('2026-08-20T09:00:00.000Z'));
    });

    test('preserves nullable fields and existing default parsing behavior', () {
      final before = DateTime.now();
      final model = TripExpenseModel.fromMap({
        'id': 'expense-2',
        'company_id': 'company-1',
        'trip_id': 'trip-2',
        'expense_type_id': null,
        'expense_name': null,
        'amount': null,
        'paid_by': null,
        'expense_date': null,
        'notes': null,
        'created_at': null,
        'updated_at': null,
      });
      final after = DateTime.now();

      expect(model.expenseTypeId, isNull);
      expect(model.expenseName, '');
      expect(model.amount, 0.0);
      expect(model.paidBy, 'company');
      expect(model.expenseDate.isBefore(before), isFalse);
      expect(model.expenseDate.isAfter(after), isFalse);
      expect(model.notes, isNull);
      expect(model.expenseTypeName, isNull);
      expect(model.createdAt, isNull);
      expect(model.updatedAt, isNull);
    });

    test('prefers direct expense-type display-name alias', () {
      final model = TripExpenseModel.fromMap({
        'id': 'expense-3',
        'company_id': 'company-1',
        'trip_id': 'trip-3',
        'expense_name': 'Toll',
        'amount': 20,
        'paid_by': 'company',
        'expense_date': '2026-08-21',
        'expense_type_name': 'Alias Type',
        'expense_type': {'name': 'Singular Type'},
        'expense_types': {'name': 'Plural Type'},
      });

      expect(model.expenseTypeName, 'Alias Type');
    });

    test('preserves singular expense-type relationship fallback', () {
      final model = TripExpenseModel.fromMap({
        'id': 'expense-4',
        'company_id': 'company-1',
        'trip_id': 'trip-4',
        'expense_name': 'Parking',
        'amount': 15,
        'paid_by': 'company',
        'expense_date': '2026-08-21',
        'expense_type': {'name': 'Singular Type'},
      });

      expect(model.expenseTypeName, 'Singular Type');
    });

    test('preserves plural Supabase expense-type relationship fallback', () {
      final model = TripExpenseModel.fromMap({
        'id': 'expense-5',
        'company_id': 'company-1',
        'trip_id': 'trip-5',
        'expense_name': 'Permit',
        'amount': 30,
        'paid_by': 'company',
        'expense_date': '2026-08-21',
        'expense_types': {'name': 'Plural Type'},
      });

      expect(model.expenseTypeName, 'Plural Type');
    });

    test('maps model to Domain entity without changing values', () {
      final expenseDate = DateTime.utc(2026, 8, 22);
      final createdAt = DateTime.utc(2026, 8, 22, 6);
      final model = TripExpenseModel(
        id: 'expense-6',
        companyId: 'company-1',
        tripId: 'trip-6',
        expenseTypeId: 'type-6',
        expenseName: 'Fuel',
        amount: 200,
        paidBy: 'driver_advance',
        expenseDate: expenseDate,
        notes: 'note',
        expenseTypeName: 'Fuel Type',
        createdAt: createdAt,
      );

      final entity = model.toEntity();

      expect(entity.id, model.id);
      expect(entity.companyId, model.companyId);
      expect(entity.tripId, model.tripId);
      expect(entity.expenseTypeId, model.expenseTypeId);
      expect(entity.expenseName, model.expenseName);
      expect(entity.amount, model.amount);
      expect(entity.paidBy, TripExpensePaidBy.driverAdvance);
      expect(entity.expenseDate, same(expenseDate));
      expect(entity.notes, model.notes);
      expect(entity.expenseTypeName, model.expenseTypeName);
      expect(entity.createdAt, same(createdAt));
    });
  });

  group('Trip Expense mapper', () {
    test('builds stable audit values', () {
      final model = TripExpenseModel(
        id: 'expense-1',
        companyId: 'company-1',
        tripId: 'trip-1',
        expenseTypeId: 'type-1',
        expenseName: 'Fuel',
        amount: 125.75,
        paidBy: 'company',
        expenseDate: DateTime(2026, 8, 20, 18, 30),
        notes: 'diesel',
        expenseTypeName: 'Fuel Type',
        createdAt: DateTime.utc(2026, 8, 20, 8),
        updatedAt: DateTime.utc(2026, 8, 20, 9),
      );

      final values = model.toAuditValues();

      expect(values[DbCommonFields.id], 'expense-1');
      expect(values[DbCommonFields.companyId], 'company-1');
      expect(values[TripExpenseDbFields.tripId], 'trip-1');
      expect(values[TripExpenseDbFields.expenseTypeId], 'type-1');
      expect(values[TripExpenseDbFields.expenseName], 'Fuel');
      expect(values[TripExpenseDbFields.amount], 125.75);
      expect(values[TripExpenseDbFields.paidBy], 'company');
      expect(values[TripExpenseDbFields.expenseDate], '2026-08-20');
      expect(values[TripExpenseDbFields.notes], 'diesel');
      expect(values[TripExpenseDbFields.expenseTypeNameAlias], 'Fuel Type');
      expect(values[DbCommonFields.createdAt], '2026-08-20T08:00:00.000Z');
      expect(values[DbCommonFields.updatedAt], '2026-08-20T09:00:00.000Z');
    });

    test('builds the existing insert payload with date-only formatting', () {
      final data = TripExpenseWriteData(
        companyId: 'company-1',
        tripId: 'trip-1',
        expenseTypeId: 'type-1',
        expenseName: 'Fuel',
        amount: 150.5,
        paidBy: TripExpensePaidBy.driverCash,
        expenseDate: DateTime(2026, 8, 21, 23, 30),
        notes: 'note',
      );

      expect(data.toInsertMap(), {
        'company_id': 'company-1',
        'trip_id': 'trip-1',
        'expense_type_id': 'type-1',
        'expense_name': 'Fuel',
        'amount': 150.5,
        'paid_by': 'driver_cash',
        'expense_date': '2026-08-21',
        'notes': 'note',
      });
    });

    test('builds the existing update payload with UTC updated timestamp', () {
      final data = TripExpenseWriteData(
        companyId: 'company-1',
        tripId: 'trip-1',
        expenseTypeId: null,
        expenseName: 'Other',
        amount: 75,
        paidBy: TripExpensePaidBy.other,
        expenseDate: DateTime(2026, 8, 22, 9),
        notes: null,
      );

      final map = data.toUpdateMap();

      expect(map[TripExpenseDbFields.expenseTypeId], isNull);
      expect(map[TripExpenseDbFields.expenseName], 'Other');
      expect(map[TripExpenseDbFields.amount], 75.0);
      expect(map[TripExpenseDbFields.paidBy], 'other');
      expect(map[TripExpenseDbFields.expenseDate], '2026-08-22');
      expect(map[TripExpenseDbFields.notes], isNull);
      final updatedAt = DateTime.tryParse(
        map[DbCommonFields.updatedAt] as String,
      );
      expect(updatedAt, isNotNull);
      expect(updatedAt?.isUtc, isTrue);
    });
  });
}
