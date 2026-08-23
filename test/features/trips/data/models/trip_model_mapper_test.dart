import 'package:horus_system/core/data/constants/db_common_fields.dart';
import 'package:horus_system/features/trips/data/constants/trip_db_fields.dart';
import 'package:horus_system/features/trips/data/mappers/trip_mapper.dart';
import 'package:horus_system/features/trips/data/models/trip_model.dart';
import 'package:horus_system/features/trips/data/models/trip_status_history_model.dart';
import 'package:horus_system/features/trips/domain/entities/trip_status.dart';
import 'package:horus_system/features/trips/domain/entities/trip_write_data.dart';
import 'package:test/test.dart';

void main() {
  group('Trips database constants', () {
    test('preserve table, lookup, select, and open-trip identifiers', () {
      expect(TripDbFields.tableName, 'trips');
      expect(TripStatusHistoryDbFields.tableName, 'trip_status_history');
      expect(TripLookupDbFields.customersTableName, 'customers');
      expect(TripLookupDbFields.routesTableName, 'routes');
      expect(TripLookupDbFields.driversTableName, 'drivers');
      expect(TripLookupDbFields.tractorHeadsTableName, 'tractor_heads');
      expect(TripLookupDbFields.trailersTableName, 'trailers');
      expect(
        TripDbFields.openTripStatusFilter,
        'status.eq.created,status.eq.assigned,status.eq.loaded,'
        'status.eq.on_road,status.eq.arrived',
      );
      expect(
        TripDbFields.allColumns,
        contains('customers!trips_company_customer_fk(name)'),
      );
      expect(
        TripDbFields.allColumns,
        contains(
          'routes!trips_company_route_fk(loading_location, '
          'unloading_location)',
        ),
      );
      expect(
        TripDbFields.allColumns,
        contains('drivers!trips_company_driver_fk(full_name)'),
      );
      expect(
        TripDbFields.allColumns,
        contains('tractor_heads!trips_company_tractor_fk(plate_number)'),
      );
      expect(
        TripDbFields.allColumns,
        contains('trailers!trips_company_trailer_fk(plate_number)'),
      );
    });
  });

  group('TripModel', () {
    test(
      'parses persistence values, numeric fields, dates, and nested relations',
      () {
        final model = TripModel.fromMap({
          'id': 'trip-1',
          'company_id': 'company-1',
          'customer_id': 'customer-1',
          'route_id': 'route-1',
          'driver_id': 'driver-1',
          'tractor_head_id': 'tractor-1',
          'trailer_id': 'trailer-1',
          'status': 'on_road',
          'loading_order_number': 'LO-100',
          'waybill_number': 'WB-200',
          'quantity_tons': '12.5',
          'freight_price': 4500,
          'total_expenses': '875.25',
          'scheduled_loading_at': '2026-08-20T06:00:00.000Z',
          'scheduled_delivery_at': '2026-08-21T08:00:00.000Z',
          'actual_loading_at': '2026-08-20T06:30:00.000Z',
          'actual_delivery_at': null,
          'notes': 'priority',
          'customers': {'name': 'Customer A'},
          'routes': {
            'loading_location': 'Dubai',
            'unloading_location': 'Abu Dhabi',
          },
          'drivers': {'full_name': 'Driver A'},
          'tractor_heads': {'plate_number': 'TH-123'},
          'trailers': {'plate_number': 'TR-456'},
          'created_at': '2026-08-19T10:00:00.000Z',
          'updated_at': '2026-08-20T07:00:00.000Z',
        });

        expect(model.id, 'trip-1');
        expect(model.companyId, 'company-1');
        expect(model.customerId, 'customer-1');
        expect(model.routeId, 'route-1');
        expect(model.driverId, 'driver-1');
        expect(model.tractorHeadId, 'tractor-1');
        expect(model.trailerId, 'trailer-1');
        expect(model.status, 'on_road');
        expect(model.loadingOrderNumber, 'LO-100');
        expect(model.waybillNumber, 'WB-200');
        expect(model.quantityTons, 12.5);
        expect(model.freightPrice, 4500.0);
        expect(model.totalExpenses, 875.25);
        expect(
          model.scheduledLoadingAt,
          DateTime.parse('2026-08-20T06:00:00.000Z'),
        );
        expect(
          model.scheduledDeliveryAt,
          DateTime.parse('2026-08-21T08:00:00.000Z'),
        );
        expect(
          model.actualLoadingAt,
          DateTime.parse('2026-08-20T06:30:00.000Z'),
        );
        expect(model.actualDeliveryAt, isNull);
        expect(model.notes, 'priority');
        expect(model.customerName, 'Customer A');
        expect(model.routeName, 'Dubai -> Abu Dhabi');
        expect(model.driverName, 'Driver A');
        expect(model.tractorHeadPlateNumber, 'TH-123');
        expect(model.trailerPlateNumber, 'TR-456');
        expect(model.createdAt, DateTime.parse('2026-08-19T10:00:00.000Z'));
        expect(model.updatedAt, DateTime.parse('2026-08-20T07:00:00.000Z'));
      },
    );

    test('preserves nullable fields and singular relationship fallbacks', () {
      final model = TripModel.fromMap({
        'id': 'trip-2',
        'company_id': 'company-1',
        'customer_id': 'customer-2',
        'route_id': 'route-2',
        'driver_id': null,
        'tractor_head_id': null,
        'trailer_id': null,
        'status': null,
        'loading_order_number': null,
        'waybill_number': null,
        'quantity_tons': null,
        'freight_price': null,
        'total_expenses': null,
        'scheduled_loading_at': null,
        'scheduled_delivery_at': null,
        'actual_loading_at': null,
        'actual_delivery_at': null,
        'notes': null,
        'customer': {'name': 'Customer B'},
        'route': {'name': 'Fallback Route'},
        'driver': {'full_name': 'Driver B'},
        'tractor_head': {'plate_number': 'TH-200'},
        'trailer': {'plate_number': 'TR-200'},
        'created_at': null,
        'updated_at': null,
      });

      expect(model.status, 'created');
      expect(model.driverId, isNull);
      expect(model.tractorHeadId, isNull);
      expect(model.trailerId, isNull);
      expect(model.quantityTons, isNull);
      expect(model.freightPrice, isNull);
      expect(model.totalExpenses, isNull);
      expect(model.scheduledLoadingAt, isNull);
      expect(model.scheduledDeliveryAt, isNull);
      expect(model.actualLoadingAt, isNull);
      expect(model.actualDeliveryAt, isNull);
      expect(model.createdAt, isNull);
      expect(model.updatedAt, isNull);
      expect(model.customerName, 'Customer B');
      expect(model.routeName, 'Fallback Route');
      expect(model.driverName, 'Driver B');
      expect(model.tractorHeadPlateNumber, 'TH-200');
      expect(model.trailerPlateNumber, 'TR-200');
    });

    test('maps model to Domain entity without changing values', () {
      final expenseDate = DateTime.utc(2026, 8, 20);
      final model = TripModel(
        id: 'trip-3',
        companyId: 'company-1',
        customerId: 'customer-1',
        routeId: 'route-1',
        status: 'assigned',
        driverId: 'driver-1',
        quantityTons: 20,
        totalExpenses: 500,
        scheduledLoadingAt: expenseDate,
        customerName: 'Customer A',
        routeName: 'Dubai -> Abu Dhabi',
      );

      final entity = model.toEntity();

      expect(entity.id, model.id);
      expect(entity.companyId, model.companyId);
      expect(entity.customerId, model.customerId);
      expect(entity.routeId, model.routeId);
      expect(entity.driverId, model.driverId);
      expect(entity.status, TripStatus.assigned);
      expect(entity.quantityTons, model.quantityTons);
      expect(entity.totalExpenses, model.totalExpenses);
      expect(entity.scheduledLoadingAt, same(expenseDate));
      expect(entity.customerName, model.customerName);
      expect(entity.routeName, model.routeName);
    });
  });

  group('TripStatusHistoryModel', () {
    test('parses history values including nullable old-status and actor fields', () {
      final model = TripStatusHistoryModel.fromMap({
        'id': 'history-1',
        'company_id': 'company-1',
        'trip_id': 'trip-1',
        'old_status': null,
        'new_status': 'assigned',
        'changed_by': null,
        'changed_by_name': null,
        'changed_by_role': null,
        'notes': null,
        'changed_at': '2026-08-20T09:00:00.000Z',
      });

      expect(model.id, 'history-1');
      expect(model.companyId, 'company-1');
      expect(model.tripId, 'trip-1');
      expect(model.oldStatus, isNull);
      expect(model.newStatus, 'assigned');
      expect(model.changedByUserId, isNull);
      expect(model.changedByName, isNull);
      expect(model.changedByRole, isNull);
      expect(model.notes, isNull);
      expect(model.changedAt, DateTime.parse('2026-08-20T09:00:00.000Z'));
    });

    test('maps history model to Domain statuses and actor values', () {
      final changedAt = DateTime.utc(2026, 8, 20, 9);
      final model = TripStatusHistoryModel(
        id: 'history-2',
        companyId: 'company-1',
        tripId: 'trip-1',
        oldStatus: 'created',
        newStatus: 'assigned',
        changedByUserId: 'user-1',
        changedByName: 'User A',
        changedByRole: 'admin',
        notes: 'assigned driver',
        changedAt: changedAt,
      );

      final entity = model.toEntity();

      expect(entity.id, model.id);
      expect(entity.companyId, model.companyId);
      expect(entity.tripId, model.tripId);
      expect(entity.oldStatus, TripStatus.created);
      expect(entity.newStatus, TripStatus.assigned);
      expect(entity.changedByUserId, model.changedByUserId);
      expect(entity.changedByName, model.changedByName);
      expect(entity.changedByRole, model.changedByRole);
      expect(entity.notes, model.notes);
      expect(entity.changedAt, same(changedAt));
    });
  });

  group('Trip mapper', () {
    test('builds stable audit values', () {
      final model = TripModel(
        id: 'trip-1',
        companyId: 'company-1',
        customerId: 'customer-1',
        routeId: 'route-1',
        status: 'loaded',
        driverId: 'driver-1',
        tractorHeadId: 'tractor-1',
        trailerId: 'trailer-1',
        loadingOrderNumber: 'LO-1',
        waybillNumber: 'WB-1',
        quantityTons: 10.5,
        freightPrice: 2500,
        totalExpenses: 300,
        scheduledLoadingAt: DateTime.utc(2026, 8, 20, 6),
        scheduledDeliveryAt: DateTime.utc(2026, 8, 21, 8),
        actualLoadingAt: DateTime.utc(2026, 8, 20, 7),
        actualDeliveryAt: DateTime.utc(2026, 8, 21, 9),
        notes: 'note',
        customerName: 'Customer A',
        routeName: 'Dubai -> Abu Dhabi',
        driverName: 'Driver A',
        tractorHeadPlateNumber: 'TH-1',
        trailerPlateNumber: 'TR-1',
        createdAt: DateTime.utc(2026, 8, 19, 10),
        updatedAt: DateTime.utc(2026, 8, 20, 7),
      );

      final values = model.toAuditValues();

      expect(values[DbCommonFields.id], 'trip-1');
      expect(values[DbCommonFields.companyId], 'company-1');
      expect(values[TripDbFields.customerId], 'customer-1');
      expect(values[TripDbFields.routeId], 'route-1');
      expect(values[TripDbFields.driverId], 'driver-1');
      expect(values[TripDbFields.tractorHeadId], 'tractor-1');
      expect(values[TripDbFields.trailerId], 'trailer-1');
      expect(values[TripDbFields.status], 'loaded');
      expect(values[TripDbFields.loadingOrderNumber], 'LO-1');
      expect(values[TripDbFields.waybillNumber], 'WB-1');
      expect(values[TripDbFields.quantityTons], 10.5);
      expect(values[TripDbFields.freightPrice], 2500.0);
      expect(values[TripDbFields.totalExpenses], 300.0);
      expect(
        values[TripDbFields.scheduledLoadingAt],
        '2026-08-20T06:00:00.000Z',
      );
      expect(
        values[TripDbFields.actualDeliveryAt],
        '2026-08-21T09:00:00.000Z',
      );
      expect(values[TripDbFields.customerNameAlias], 'Customer A');
      expect(values[TripDbFields.routeNameAlias], 'Dubai -> Abu Dhabi');
      expect(values[TripDbFields.driverNameAlias], 'Driver A');
      expect(values[TripDbFields.tractorHeadPlateNumberAlias], 'TH-1');
      expect(values[TripDbFields.trailerPlateNumberAlias], 'TR-1');
      expect(values[DbCommonFields.createdAt], '2026-08-19T10:00:00.000Z');
      expect(values[DbCommonFields.updatedAt], '2026-08-20T07:00:00.000Z');
    });

    test('builds the existing insert payload', () {
      final data = TripWriteData(
        companyId: 'company-1',
        customerId: 'customer-1',
        routeId: 'route-1',
        driverId: 'driver-1',
        tractorHeadId: 'tractor-1',
        trailerId: 'trailer-1',
        loadingOrderNumber: 'LO-1',
        waybillNumber: 'WB-1',
        quantityTons: 15,
        freightPrice: 3500,
        scheduledLoadingAt: DateTime.parse('2026-08-20T10:00:00+04:00'),
        scheduledDeliveryAt: DateTime.parse('2026-08-21T12:00:00+04:00'),
        actualLoadingAt: null,
        actualDeliveryAt: null,
        notes: 'note',
      );

      expect(data.toInsertMap(), {
        'company_id': 'company-1',
        'customer_id': 'customer-1',
        'route_id': 'route-1',
        'driver_id': 'driver-1',
        'tractor_head_id': 'tractor-1',
        'trailer_id': 'trailer-1',
        'loading_order_number': 'LO-1',
        'waybill_number': 'WB-1',
        'quantity_tons': 15.0,
        'freight_price': 3500.0,
        'scheduled_loading_at': '2026-08-20T06:00:00.000Z',
        'scheduled_delivery_at': '2026-08-21T08:00:00.000Z',
        'actual_loading_at': null,
        'actual_delivery_at': null,
        'notes': 'note',
      });
    });

    test('builds the existing update payload with an updated timestamp', () {
      const data = TripWriteData(
        companyId: 'company-1',
        customerId: 'customer-2',
        routeId: 'route-2',
      );

      final map = data.toUpdateMap();

      expect(map[TripDbFields.customerId], 'customer-2');
      expect(map[TripDbFields.routeId], 'route-2');
      expect(map[TripDbFields.driverId], isNull);
      expect(map[TripDbFields.tractorHeadId], isNull);
      expect(map[TripDbFields.trailerId], isNull);
      expect(map[TripDbFields.loadingOrderNumber], isNull);
      expect(map[TripDbFields.waybillNumber], isNull);
      expect(map[TripDbFields.quantityTons], isNull);
      expect(map[TripDbFields.freightPrice], isNull);
      expect(map[TripDbFields.scheduledLoadingAt], isNull);
      expect(map[TripDbFields.scheduledDeliveryAt], isNull);
      expect(map[TripDbFields.actualLoadingAt], isNull);
      expect(map[TripDbFields.actualDeliveryAt], isNull);
      expect(map[TripDbFields.notes], isNull);
      final updatedAt = DateTime.tryParse(
        map[DbCommonFields.updatedAt] as String,
      );
      expect(updatedAt, isNotNull);
      expect(updatedAt?.isUtc, isTrue);
    });

    test('builds the existing trip-status update payload', () {
      final map = TripStatus.arrived.toTripStatusUpdateMap();

      expect(map[TripDbFields.status], 'arrived');
      final updatedAt = DateTime.tryParse(
        map[DbCommonFields.updatedAt] as String,
      );
      expect(updatedAt, isNotNull);
      expect(updatedAt?.isUtc, isTrue);
    });

    test('builds the existing status-history insert payload', () {
      final map = TripStatus.assigned.toHistoryInsertMap(
        companyId: 'company-1',
        tripId: 'trip-1',
        oldStatus: TripStatus.created,
        actorRole: 'admin',
        notes: 'assigned driver',
      );

      expect(map, {
        'company_id': 'company-1',
        'trip_id': 'trip-1',
        'old_status': 'created',
        'new_status': 'assigned',
        'changed_by_role': 'admin',
        'notes': 'assigned driver',
      });
    });
  });
}
