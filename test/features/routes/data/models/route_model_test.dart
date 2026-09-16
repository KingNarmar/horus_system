import 'package:horus_system/features/routes/data/models/route_model.dart';
import 'package:test/test.dart';

void main() {
  group('RouteModel', () {
    test('preserves exact freight-rate decimal text from persistence', () {
      final model = RouteModel.fromMap(
        _persistenceMap(
          defaultFreightRate: '1250.5000',
          createdAt: '2026-08-01T10:20:30.000Z',
          updatedAt: '2026-08-02T11:21:31.000Z',
        ),
      );

      expect(model.id, 'route-1');
      expect(model.companyId, 'company-1');
      expect(model.loadingLocation, 'Dubai');
      expect(model.unloadingLocation, 'Abu Dhabi');
      expect(model.defaultFreightRatePerTonDecimal, '1250.5000');
      expect(model.createdAt, DateTime.utc(2026, 8, 1, 10, 20, 30));
      expect(model.updatedAt, DateTime.utc(2026, 8, 2, 11, 21, 31));
    });

    test(
      'normalizes supported numeric persistence representations to text',
      () {
        final cases = <Object, String>{
          1250: '1250',
          1250.5: '1250.5',
          '1250.7500': '1250.7500',
        };

        for (final entry in cases.entries) {
          final model = RouteModel.fromMap(
            _persistenceMap(defaultFreightRate: entry.key),
          );
          expect(model.defaultFreightRatePerTonDecimal, entry.value);
        }
      },
    );

    test('preserves nullable persistence fields', () {
      final model = RouteModel.fromMap(
        _persistenceMap(
          governorateFrom: null,
          governorateTo: null,
          defaultFreightRate: null,
          notes: null,
          createdAt: null,
          updatedAt: null,
        ),
      );

      expect(model.governorateFrom, isNull);
      expect(model.governorateTo, isNull);
      expect(model.defaultFreightRatePerTonDecimal, isNull);
      expect(model.notes, isNull);
      expect(model.createdAt, isNull);
      expect(model.updatedAt, isNull);
    });

    test('defaults active state to true when persistence key is absent', () {
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
  Object? defaultFreightRate = '1250.00',
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
    'default_freight_price': defaultFreightRate,
    'notes': notes,
    'is_active': true,
    'created_at': createdAt,
    'updated_at': updatedAt,
  };
}
