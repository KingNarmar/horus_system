import 'package:horus_system/core/domain/value_objects/business_date.dart';
import 'package:horus_system/features/driver_finance/data/models/driver_financial_movement_model.dart';
import 'package:horus_system/features/driver_finance/domain/entities/driver_financial_movement_type.dart';
import 'package:test/test.dart';

void main() {
  group('DriverFinancialMovementModel', () {
    test('decodes exact money date and UTC system timestamps', () {
      final model = DriverFinancialMovementModel.fromMap({
        'id': 'movement-1',
        'company_id': 'company-1',
        'driver_id': 'driver-1',
        'trip_id': null,
        'movement_type': 'advance',
        'amount': '125.50',
        'amount_minor_units': 12550,
        'currency_code': 'AED',
        'currency_fraction_digits': 2,
        'movement_date': '2026-08-23',
        'notes': 'note',
        'created_at': '2026-08-23T09:00:00Z',
        'updated_at': '2026-08-23T10:00:00+00:00',
      });

      expect(model.type, DriverFinancialMovementType.advance);
      expect(model.amount, 125.5);
      expect(model.amountMinorUnits, 12550);
      expect(model.currencyCode, 'AED');
      expect(model.currencyFractionDigits, 2);
      expect(model.movementDate, BusinessDate(year: 2026, month: 8, day: 23));
      expect(model.createdAt, DateTime.utc(2026, 8, 23, 9));
      expect(model.createdAt?.isUtc, isTrue);
      expect(model.updatedAt, DateTime.utc(2026, 8, 23, 10));
      expect(model.updatedAt?.isUtc, isTrue);
    });

    test('keeps exact fields optional for legacy rows', () {
      final model = DriverFinancialMovementModel.fromMap({
        'id': 'movement-1',
        'company_id': 'company-1',
        'driver_id': 'driver-1',
        'trip_id': null,
        'movement_type': 'advance',
        'amount': 125.5,
        'movement_date': '2026-08-23',
        'notes': null,
        'created_at': null,
        'updated_at': null,
      });

      expect(model.amountMinorUnits, isNull);
      expect(model.currencyCode, isNull);
      expect(model.currencyFractionDigits, isNull);
    });

    test('rejects timestamp-shaped movement date instead of defaulting', () {
      expect(
        () => DriverFinancialMovementModel.fromMap({
          'id': 'movement-1',
          'company_id': 'company-1',
          'driver_id': 'driver-1',
          'trip_id': null,
          'movement_type': 'advance',
          'amount': 125.5,
          'movement_date': '2026-08-23T00:00:00Z',
          'notes': null,
          'created_at': '2026-08-23T09:00:00Z',
          'updated_at': null,
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects system timestamp without UTC or explicit offset', () {
      expect(
        () => DriverFinancialMovementModel.fromMap({
          'id': 'movement-1',
          'company_id': 'company-1',
          'driver_id': 'driver-1',
          'trip_id': null,
          'movement_type': 'advance',
          'amount': 125.5,
          'movement_date': '2026-08-23',
          'notes': null,
          'created_at': '2026-08-23T09:00:00',
          'updated_at': null,
        }),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
