import 'package:horus_system/features/routes/data/mappers/route_mapper.dart';
import 'package:horus_system/features/routes/data/models/route_model.dart';
import 'package:horus_system/features/routes/domain/entities/route_write_data.dart';
import 'package:test/test.dart';

void main() {
  group('RouteModelMapper', () {
    test('maps model to entity without changing values', () {
      final model = _model();

      final entity = model.toEntity();

      expect(entity.id, model.id);
      expect(entity.companyId, model.companyId);
      expect(entity.loadingLocation, model.loadingLocation);
      expect(entity.unloadingLocation, model.unloadingLocation);
      expect(entity.governorateFrom, model.governorateFrom);
      expect(entity.governorateTo, model.governorateTo);
      expect(entity.defaultFreightPrice, model.defaultFreightPrice);
      expect(entity.notes, model.notes);
      expect(entity.isActive, model.isActive);
      expect(entity.createdAt, model.createdAt);
      expect(entity.updatedAt, model.updatedAt);
    });

    test('maps model to the existing audit persistence values', () {
      final values = _model().toAuditValues();

      expect(values, {
        'id': 'route-1',
        'company_id': 'company-1',
        'loading_location': 'Dubai',
        'unloading_location': 'Abu Dhabi',
        'governorate_from': 'Dubai',
        'governorate_to': 'Abu Dhabi',
        'default_freight_price': 1250.5,
        'notes': 'Priority route',
        'is_active': true,
        'created_at': '2026-08-01T10:20:30.000Z',
        'updated_at': '2026-08-02T11:21:31.000Z',
      });
    });
  });

  group('RouteWriteDataMapper', () {
    test('maps write data to the existing insert persistence map', () {
      final map = _writeData().toInsertMap();

      expect(map, {
        'company_id': 'company-1',
        'loading_location': 'Dubai',
        'unloading_location': 'Abu Dhabi',
        'governorate_from': 'Dubai',
        'governorate_to': 'Abu Dhabi',
        'default_freight_price': 1250.5,
        'notes': 'Priority route',
      });
    });

    test('maps write data to the existing update persistence map', () {
      final before = DateTime.now().toUtc();

      final map = _writeData().toUpdateMap();

      final after = DateTime.now().toUtc();
      expect(map.keys.toSet(), {
        'loading_location',
        'unloading_location',
        'governorate_from',
        'governorate_to',
        'default_freight_price',
        'notes',
        'updated_at',
      });
      expect(map['loading_location'], 'Dubai');
      expect(map['unloading_location'], 'Abu Dhabi');
      expect(map['governorate_from'], 'Dubai');
      expect(map['governorate_to'], 'Abu Dhabi');
      expect(map['default_freight_price'], 1250.5);
      expect(map['notes'], 'Priority route');

      final updatedAt = DateTime.parse(map['updated_at'] as String);
      expect(updatedAt.isBefore(before), isFalse);
      expect(updatedAt.isAfter(after), isFalse);
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
    defaultFreightPrice: 1250.5,
    notes: 'Priority route',
    isActive: true,
    createdAt: DateTime.utc(2026, 8, 1, 10, 20, 30),
    updatedAt: DateTime.utc(2026, 8, 2, 11, 21, 31),
  );
}

RouteWriteData _writeData() {
  return const RouteWriteData(
    companyId: 'company-1',
    loadingLocation: 'Dubai',
    unloadingLocation: 'Abu Dhabi',
    governorateFrom: 'Dubai',
    governorateTo: 'Abu Dhabi',
    defaultFreightPrice: 1250.5,
    notes: 'Priority route',
  );
}
