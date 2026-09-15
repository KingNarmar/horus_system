import 'package:horus_system/core/domain/value_objects/currency_code.dart';
import 'package:horus_system/core/domain/value_objects/currency_configuration.dart';
import 'package:horus_system/core/domain/value_objects/money.dart';
import 'package:horus_system/features/routes/data/mappers/route_mapper.dart';
import 'package:horus_system/features/routes/data/models/route_model.dart';
import 'package:horus_system/features/routes/domain/entities/route_write_data.dart';
import 'package:test/test.dart';

void main() {
  final configuration = CurrencyConfiguration.tryCreate(
    currencyCode: 'AED',
    fractionDigits: 2,
  )!;
  final currency = configuration.currency;

  group('RouteModelMapper', () {
    test('maps exact decimal rate to Money', () {
      final model = _model();

      final entity = model.toEntity(financialConfiguration: configuration);

      expect(entity.id, model.id);
      expect(
        entity.defaultFreightRatePerTon,
        Money(minorUnits: 125050, currency: currency),
      );
    });

    test('uses semantic audit key rather than physical legacy column name', () {
      final values = _model().toAuditValues();

      expect(values['default_freight_rate_per_ton'], '1250.50');
      expect(values.containsKey('default_freight_price'), isFalse);
    });
  });

  group('RouteWriteDataMapper', () {
    test('encodes Money exactly into physical compatibility column', () {
      final map = _writeData(currency).toInsertMap(
        financialConfiguration: configuration,
      );

      expect(map['company_id'], 'company-1');
      expect(map['default_freight_price'], '1250.50');
    });

    test('encodes update rate and timestamp without floating point', () {
      final map = _writeData(currency).toUpdateMap(
        financialConfiguration: configuration,
      );

      expect(map['default_freight_price'], '1250.50');
      final updatedAt = DateTime.parse(map['updated_at'] as String);
      expect(updatedAt.isUtc, isTrue);
    });

    test('rejects missing financial configuration when Money is present', () {
      expect(
        () => _writeData(currency).toInsertMap(financialConfiguration: null),
        throwsStateError,
      );
    });
  });
}

RouteModel _model() {
  return RouteModel(
    id: 'route-1',
    companyId: 'company-1',
    loadingLocation: 'Dubai',
    unloadingLocation: 'Abu Dhabi',
    governorateFrom: 'Dubai',
    governorateTo: 'Abu Dhabi',
    defaultFreightRatePerTonDecimal: '1250.50',
    notes: 'Priority route',
    isActive: true,
    createdAt: DateTime.utc(2026, 8, 1, 10, 20, 30),
    updatedAt: DateTime.utc(2026, 8, 2, 11, 21, 31),
  );
}

RouteWriteData _writeData(CurrencyCode currency) {
  return RouteWriteData(
    companyId: 'company-1',
    loadingLocation: 'Dubai',
    unloadingLocation: 'Abu Dhabi',
    governorateFrom: 'Dubai',
    governorateTo: 'Abu Dhabi',
    defaultFreightRatePerTon: Money(minorUnits: 125050, currency: currency),
    notes: 'Priority route',
  );
}
