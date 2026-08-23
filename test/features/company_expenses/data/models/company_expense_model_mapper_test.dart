import 'package:horus_system/core/data/constants/db_common_fields.dart';
import 'package:horus_system/features/company_expenses/data/constants/company_expense_db_fields.dart';
import 'package:horus_system/features/company_expenses/data/mappers/company_expense_mapper.dart';
import 'package:horus_system/features/company_expenses/data/models/company_expense_category_model.dart';
import 'package:horus_system/features/company_expenses/data/models/company_expense_model.dart';
import 'package:horus_system/features/company_expenses/domain/entities/company_expense_void_data.dart';
import 'package:horus_system/features/company_expenses/domain/entities/company_expense_write_data.dart';
import 'package:test/test.dart';

void main() {
  group('Company Expense database constants', () {
    test('preserve current table and lookup identifiers', () {
      expect(CompanyExpenseDbFields.tableName, 'company_expenses');
      expect(
        CompanyExpenseCategoryDbFields.tableName,
        'company_expense_categories',
      );
      expect(CompanyExpenseLookupDbFields.driversTableName, 'drivers');
      expect(
        CompanyExpenseLookupDbFields.tractorHeadsTableName,
        'tractor_heads',
      );
      expect(CompanyExpenseLookupDbFields.trailersTableName, 'trailers');
      expect(CompanyExpenseLookupDbFields.tripsTableName, 'trips');
    });
  });

  group('CompanyExpenseModel', () {
    test(
      'parses persistence values, numeric amount, dates, and nullable links',
      () {
        final model = CompanyExpenseModel.fromMap({
          'id': 'expense-1',
          'company_id': 'company-1',
          'category_id': 'category-1',
          'driver_id': null,
          'tractor_head_id': 'tractor-1',
          'trailer_id': null,
          'trip_id': 'trip-1',
          'amount': '1250.75',
          'expense_date': '2026-08-20',
          'reference_number': 'REF-10',
          'notes': null,
          'is_voided': true,
          'voided_at': '2026-08-21T08:30:00.000Z',
          'voided_by': 'user-1',
          'void_reason': 'duplicate',
          'created_at': '2026-08-20T06:00:00.000Z',
          'updated_at': '2026-08-21T08:30:00.000Z',
        });

        expect(model.id, 'expense-1');
        expect(model.companyId, 'company-1');
        expect(model.categoryId, 'category-1');
        expect(model.driverId, isNull);
        expect(model.tractorHeadId, 'tractor-1');
        expect(model.trailerId, isNull);
        expect(model.tripId, 'trip-1');
        expect(model.amount, 1250.75);
        expect(model.expenseDate, DateTime.parse('2026-08-20'));
        expect(model.referenceNumber, 'REF-10');
        expect(model.notes, isNull);
        expect(model.isVoided, isTrue);
        expect(model.voidedAt, DateTime.parse('2026-08-21T08:30:00.000Z'));
        expect(model.voidedBy, 'user-1');
        expect(model.voidReason, 'duplicate');
        expect(model.createdAt, DateTime.parse('2026-08-20T06:00:00.000Z'));
        expect(model.updatedAt, DateTime.parse('2026-08-21T08:30:00.000Z'));
      },
    );

    test('maps model to the Domain entity without changing values', () {
      final expenseDate = DateTime.utc(2026, 8, 20);
      final model = CompanyExpenseModel(
        id: 'expense-1',
        companyId: 'company-1',
        categoryId: 'category-1',
        amount: 50,
        expenseDate: expenseDate,
        isVoided: false,
        driverId: 'driver-1',
        notes: 'note',
      );

      final entity = model.toEntity();

      expect(entity.id, model.id);
      expect(entity.companyId, model.companyId);
      expect(entity.categoryId, model.categoryId);
      expect(entity.driverId, model.driverId);
      expect(entity.amount, model.amount);
      expect(entity.expenseDate, same(expenseDate));
      expect(entity.notes, model.notes);
      expect(entity.isVoided, model.isVoided);
    });
  });

  group('CompanyExpenseCategoryModel', () {
    test('parses category persistence values and shared fields', () {
      final model = CompanyExpenseCategoryModel.fromMap({
        'id': 'category-1',
        'company_id': 'company-1',
        'name': 'Fuel',
        'code': 'fuel',
        'is_active': false,
        'created_at': '2026-08-01T06:00:00.000Z',
        'updated_at': '2026-08-02T06:00:00.000Z',
      });

      expect(model.id, 'category-1');
      expect(model.companyId, 'company-1');
      expect(model.name, 'Fuel');
      expect(model.code, 'fuel');
      expect(model.isActive, isFalse);
      expect(model.createdAt, DateTime.parse('2026-08-01T06:00:00.000Z'));
      expect(model.updatedAt, DateTime.parse('2026-08-02T06:00:00.000Z'));
    });
  });

  group('Company Expense mapper', () {
    test('builds stable audit values', () {
      final model = CompanyExpenseModel(
        id: 'expense-1',
        companyId: 'company-1',
        categoryId: 'category-1',
        amount: 99.5,
        expenseDate: DateTime.utc(2026, 8, 20, 14),
        isVoided: true,
        driverId: 'driver-1',
        tractorHeadId: 'tractor-1',
        trailerId: 'trailer-1',
        tripId: 'trip-1',
        referenceNumber: 'REF-1',
        notes: 'note',
        voidedAt: DateTime.utc(2026, 8, 21, 8),
        voidedBy: 'user-1',
        voidReason: 'duplicate',
        createdAt: DateTime.utc(2026, 8, 20, 6),
        updatedAt: DateTime.utc(2026, 8, 21, 8),
      );

      final values = model.toAuditValues();

      expect(values[DbCommonFields.id], 'expense-1');
      expect(values[DbCommonFields.companyId], 'company-1');
      expect(values['category_id'], 'category-1');
      expect(values['driver_id'], 'driver-1');
      expect(values['tractor_head_id'], 'tractor-1');
      expect(values['trailer_id'], 'trailer-1');
      expect(values['trip_id'], 'trip-1');
      expect(values['amount'], 99.5);
      expect(values['expense_date'], '2026-08-20');
      expect(values['reference_number'], 'REF-1');
      expect(values['notes'], 'note');
      expect(values['is_voided'], isTrue);
      expect(values['voided_at'], '2026-08-21T08:00:00.000Z');
      expect(values['voided_by'], 'user-1');
      expect(values['void_reason'], 'duplicate');
      expect(values[DbCommonFields.createdAt], '2026-08-20T06:00:00.000Z');
      expect(values[DbCommonFields.updatedAt], '2026-08-21T08:00:00.000Z');
    });

    test('builds the existing insert payload', () {
      final data = CompanyExpenseWriteData(
        companyId: 'company-1',
        categoryId: 'category-1',
        amount: 120,
        expenseDate: DateTime.utc(2026, 8, 20, 18),
        driverId: 'driver-1',
        tractorHeadId: 'tractor-1',
        trailerId: 'trailer-1',
        tripId: 'trip-1',
        referenceNumber: 'REF-2',
        notes: 'note',
      );

      expect(data.toInsertMap(), {
        'company_id': 'company-1',
        'category_id': 'category-1',
        'driver_id': 'driver-1',
        'tractor_head_id': 'tractor-1',
        'trailer_id': 'trailer-1',
        'trip_id': 'trip-1',
        'amount': 120.0,
        'expense_date': '2026-08-20',
        'reference_number': 'REF-2',
        'notes': 'note',
      });
    });

    test('builds the existing update payload with an updated timestamp', () {
      final data = CompanyExpenseWriteData(
        companyId: 'company-1',
        categoryId: 'category-2',
        amount: 80,
        expenseDate: DateTime.utc(2026, 8, 22),
      );

      final map = data.toUpdateMap();

      expect(map['category_id'], 'category-2');
      expect(map['driver_id'], isNull);
      expect(map['tractor_head_id'], isNull);
      expect(map['trailer_id'], isNull);
      expect(map['trip_id'], isNull);
      expect(map['amount'], 80.0);
      expect(map['expense_date'], '2026-08-22');
      expect(map['reference_number'], isNull);
      expect(map['notes'], isNull);
      final updatedAt = DateTime.tryParse(
        map[DbCommonFields.updatedAt] as String,
      );
      expect(updatedAt, isNotNull);
      expect(updatedAt?.isUtc, isTrue);
    });

    test('builds the existing void payload with actor metadata', () {
      const data = CompanyExpenseVoidData(
        companyId: 'company-1',
        expenseId: 'expense-1',
        reason: 'duplicate',
      );

      final map = data.toVoidMap(actorUserId: 'user-1');

      expect(map['is_voided'], isTrue);
      expect(map['voided_by'], 'user-1');
      expect(map['void_reason'], 'duplicate');
      expect(map[DbCommonFields.updatedBy], 'user-1');

      final voidedAt = DateTime.tryParse(map['voided_at'] as String);
      final updatedAt = DateTime.tryParse(
        map[DbCommonFields.updatedAt] as String,
      );
      expect(voidedAt, isNotNull);
      expect(voidedAt?.isUtc, isTrue);
      expect(updatedAt, isNotNull);
      expect(updatedAt?.isUtc, isTrue);
    });
  });
}
