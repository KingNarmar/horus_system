import 'package:horus_system/core/domain/value_objects/currency_configuration.dart';
import 'package:horus_system/core/domain/value_objects/money.dart';
import 'package:horus_system/features/trips/data/constants/trip_db_contract.dart';
import 'package:horus_system/features/trips/data/constants/trip_db_fields.dart';
import 'package:horus_system/features/trips/data/mappers/trip_mapper.dart';
import 'package:horus_system/features/trips/data/models/trip_model.dart';
import 'package:horus_system/features/trips/domain/entities/trip_status.dart';
import 'package:horus_system/features/trips/domain/entities/trip_write_data.dart';
import 'package:horus_system/features/trips/domain/value_objects/quantity_tons.dart';
import 'package:horus_system/features/trips/domain/value_objects/trip_number.dart';
import 'package:test/test.dart';

void main() {
  final configuration = CurrencyConfiguration.tryCreate(
    currencyCode: 'AED',
    fractionDigits: 2,
  )!;
  final currency = configuration.currency;

  group('Trips database constants', () {
    test(
      'preserve compatibility columns and commercial snapshot identifiers',
      () {
        expect(TripDbFields.tableName, 'trips');
        expect(TripDbFields.tripNumber, 'trip_number');
        expect(TripDbFields.quantityTons, 'quantity_tons');
        expect(
          TripDbFields.agreedFreightRatePerTon,
          'agreed_freight_rate_per_ton',
        );
        expect(TripDbFields.commercialAmount, 'freight_price');
        expect(
          TripLookupDbFields.defaultFreightRatePerTon,
          'default_freight_price',
        );
        expect(
          TripDbFields.allColumns,
          contains('customers!trips_company_customer_fk(name)'),
        );
        expect(
          TripDbFields.allColumns,
          contains(
            'routes!trips_company_route_fk(loading_location, unloading_location)',
          ),
        );
      },
    );
  });

  group('TripModel and mapper', () {
    test('preserves exact decimal text from persistence', () {
      final model = TripModel.fromMap({
        'id': 'trip-1',
        'company_id': 'company-1',
        'trip_number': 'TRP-2026-000001',
        'customer_id': 'customer-1',
        'route_id': 'route-1',
        'status': 'on_road',
        'quantity_tons': '12.375',
        'agreed_freight_rate_per_ton': '125.50',
        'freight_price': '1552.41',
        'total_expenses': '875.25',
        'customers': {'name': 'Customer A'},
        'routes': {
          'loading_location': 'Dubai',
          'unloading_location': 'Abu Dhabi',
        },
      });

      expect(model.quantityTonsDecimal, '12.375');
      expect(model.agreedFreightRatePerTonDecimal, '125.50');
      expect(model.commercialAmountDecimal, '1552.41');
      expect(model.totalExpenses, 875.25);
      expect(model.routeName, 'Dubai -> Abu Dhabi');

      final entity = model.toEntity(financialConfiguration: configuration);
      expect(entity.tripNumber, TripNumber.tryParse('TRP-2026-000001'));
      expect(entity.status, TripStatus.onRoad);
      expect(entity.quantityTons, QuantityTons.tryParse('12.375'));
      expect(
        entity.agreedFreightRatePerTon,
        Money(minorUnits: 12550, currency: currency),
      );
      expect(
        entity.commercialAmount,
        Money(minorUnits: 155241, currency: currency),
      );
    });

    test('rejects an invalid persisted Trip reference', () {
      const model = TripModel(
        id: 'bad-reference',
        companyId: 'company-1',
        tripNumber: 'bad-reference',
        customerId: 'customer-1',
        routeId: 'route-1',
        status: 'created',
      );

      expect(
        () => model.toEntity(financialConfiguration: configuration),
        throwsFormatException,
      );
    });

    test('does not fabricate a legacy rate from a historical amount', () {
      const model = TripModel(
        id: 'legacy-trip',
        companyId: 'company-1',
        tripNumber: 'TRP-2026-000001',
        customerId: 'customer-1',
        routeId: 'route-1',
        status: 'delivered',
        quantityTonsDecimal: '20.000',
        commercialAmountDecimal: '5000.00',
      );

      final entity = model.toEntity(financialConfiguration: configuration);

      expect(entity.quantityTons, QuantityTons.tryParse('20'));
      expect(entity.agreedFreightRatePerTon, isNull);
      expect(
        entity.commercialAmount,
        Money(minorUnits: 500000, currency: currency),
      );
      expect(entity.hasLegacyCommercialAmount, isTrue);
    });

    test('treats default zero freight as absent for rate-less legacy rows', () {
      const model = TripModel(
        id: 'legacy-zero',
        companyId: 'company-1',
        tripNumber: 'TRP-2026-000001',
        customerId: 'customer-1',
        routeId: 'route-1',
        status: 'created',
        commercialAmountDecimal: '0.0000',
      );

      final entity = model.toEntity(financialConfiguration: configuration);

      expect(entity.agreedFreightRatePerTon, isNull);
      expect(entity.commercialAmount, isNull);
    });
  });

  group('TripWriteData mapper', () {
    test('writes exact snapshot decimals to compatibility columns', () {
      final data = TripWriteData(
        companyId: 'company-1',
        customerId: 'customer-1',
        routeId: 'route-1',
        quantityTons: QuantityTons.tryParse('15.125'),
        agreedFreightRatePerTon: Money(minorUnits: 350050, currency: currency),
        commercialAmount: Money(minorUnits: 5294506, currency: currency),
      );

      final map = data.toInsertMap(financialConfiguration: configuration);

      expect(map[TripDbFields.quantityTons], '15.125');
      expect(map[TripDbFields.agreedFreightRatePerTon], '3500.50');
      expect(map[TripDbFields.commercialAmount], '52945.06');
    });

    test('builds exact atomic RPC parameters without inventing values', () {
      final scheduledLoadingAt = DateTime.utc(2026, 9, 18, 8, 30);
      final actualDeliveryAt = DateTime.utc(2026, 9, 18, 12, 45);
      final data = TripWriteData(
        companyId: 'company-1',
        customerId: 'customer-2',
        routeId: 'route-2',
        quantityTons: QuantityTons.tryParse('15.125'),
        agreedFreightRatePerTon: Money(minorUnits: 350050, currency: currency),
        commercialAmount: Money(minorUnits: 5294506, currency: currency),
        scheduledLoadingAt: scheduledLoadingAt,
        actualDeliveryAt: actualDeliveryAt,
      );

      final params = data.toMutationRpcParams(
        financialConfiguration: configuration,
      );

      expect(params[TripDbRpcParams.companyId], 'company-1');
      expect(params[TripDbRpcParams.customerId], 'customer-2');
      expect(params[TripDbRpcParams.routeId], 'route-2');
      expect(params[TripDbRpcParams.quantityTons], '15.125');
      expect(params[TripDbRpcParams.agreedFreightRatePerTon], '3500.50');
      expect(params[TripDbRpcParams.commercialAmount], '52945.06');
      expect(
        params[TripDbRpcParams.scheduledLoadingAt],
        scheduledLoadingAt.toIso8601String(),
      );
      expect(params[TripDbRpcParams.scheduledDeliveryAt], isNull);
      expect(params[TripDbRpcParams.actualLoadingAt], isNull);
      expect(
        params[TripDbRpcParams.actualDeliveryAt],
        actualDeliveryAt.toIso8601String(),
      );
    });
  });
}
