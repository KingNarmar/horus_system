import 'package:horus_system/features/routes/data/models/route_model.dart';
import 'package:test/test.dart';

void main() {
  group('RouteModel', () {
    test('parses the expected persistence map', () {
      final model = RouteModel.fromMap(
        _persistenceMap(
          defaultFreightPrice: 1250,
          createdAt: '2026-08-01T10:20:30.000Z',
          updatedAt: '2026-08-02T11:21:31.000Z',
        ),
      );

      expect(model.id, 'route-1');
      expect(model.companyId, 'company-1');
      expect(model.loadingLocation, 'Dubai');
      expect(model.unloadingLocation, 'Abu Dhabi');
      expect(model.governorateFrom, 'Dubai');
      expect(model.governorateTo, 'Abu Dhabi');
      expect(model.defaultFreightPrice, 1250.0);
      expect(model.notes, 'Priority route');
      expect(model.isActive, isTrue);
      expect(model.createdAt, DateTime.utc(2026, 8, 1, 10, 20, 30));
      expect(model.updatedAt, DateTime.utc(2026, 8, 2, 11, 21, 31));
    });

    test('parses supported default freight price representations', () {
      final cases = <Object, double>{
        1250: 1250.0,
        1250.5: 1250.5,
        '1250.75': 1250.75,
      };

      for (final entry in cases.entries) {
        final model = RouteModel.fromMap(
          _persistenceMap(defaultFreightPrice: entry.key),
        );

        expect(
          model.defaultFreightPrice,
          entry.value,
          reason: 'Failed to parse ${entry.key.runtimeType} freight price.',
        );
      }
    });

    test('parses nullable persistence fields', () {
      final model = RouteModel.fromMap(
        _persistenceMap(
          governorateFrom: null,
          governorateTo: null,
          defaultFreightPrice: null,
          notes: null,
          createdAt: null,
          updatedAt: null,
        ),
      );

      expect(model.governorateFrom, isNull);
      expect(model.governorateTo, isNull);
      expect(model.defaultFreightPrice, isNull);
      expect(model.notes, isNull);
      expect(model.createdAt, isNull);
      expect(model.updatedAt, isNull);
    });

    test('defaults active state to true when the persistence key is absent', () {
      final map = _persistenceMap();
      map.remove('is_active');

      final model = RouteModel.fromMap(map);

      expect(model.isActive, isTrue);
    });
  });
}

Map<String, dynamic> _persistenceMap({
  Object? governorateFrom = 'Dubai',
  Object? governorateTo = 'Abu Dhabi',
  Object? defaultFreightPrice = 1250,
  Object? notes = 'Priority route',
  Object? createdAt = '2026-08-01T10:20:30.000Z',
  Object? updatedAt = '2026-08-02T11:21:31.000Z',
}) {
  return {
    'id': 'route-1',
    'company_id': 'company-1',
    'loading_location': 'Dubai',
    'unloading_location': 'Abu Dhabi',
    'governorate_from': governorateFrom,
    'governorate_to': governorateTo,
    'default_freight_price': defaultFreightPrice,
    'notes': notes,
    'is_active': true,
    'created_at': createdAt,
    'updated_at': updatedAt,
  };
}
