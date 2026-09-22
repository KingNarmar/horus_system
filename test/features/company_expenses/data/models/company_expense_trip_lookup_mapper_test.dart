import 'package:horus_system/core/data/constants/db_common_fields.dart';
import 'package:horus_system/features/company_expenses/data/constants/company_expense_db_fields.dart';
import 'package:horus_system/features/company_expenses/data/mappers/company_expense_trip_lookup_mapper.dart';
import 'package:horus_system/features/company_expenses/data/models/company_expense_trip_lookup_model.dart';
import 'package:test/test.dart';

void main() {
  group('CompanyExpenseTripLookupModelMapper', () {
    test('prefers loading order number', () {
      final option = _model(
        loadingOrderNumber: ' LO-100 ',
        waybillNumber: 'WB-200',
        customerName: 'Customer',
        routeLoadingLocation: 'Dubai',
        routeUnloadingLocation: 'Sharjah',
      ).toLinkOption();

      expect(option.label, 'LO-100');
    });

    test('uses waybill when loading order number is unavailable', () {
      final option = _model(
        waybillNumber: ' WB-200 ',
        customerName: 'Customer',
        routeLoadingLocation: 'Dubai',
        routeUnloadingLocation: 'Sharjah',
      ).toLinkOption();

      expect(option.label, 'WB-200');
    });

    test('uses customer and route when trip references are unavailable', () {
      final option = _model(
        customerName: 'Mina',
        routeLoadingLocation: 'DUBAI',
        routeUnloadingLocation: 'SHARJAH',
      ).toLinkOption();

      expect(option.label, 'Mina - DUBAI -> SHARJAH');
    });

    test('uses customer when route is unavailable', () {
      final option = _model(customerName: 'Mina').toLinkOption();

      expect(option.label, 'Mina');
    });

    test('uses route when customer is unavailable', () {
      final option = _model(
        routeLoadingLocation: 'Dubai',
        routeUnloadingLocation: 'Sharjah',
      ).toLinkOption();

      expect(option.label, 'Dubai -> Sharjah');
    });

    test('uses id only as the final fallback', () {
      final option = _model().toLinkOption();

      expect(option.label, _tripId);
    });

    test('reads nested customer and route projection from Supabase row', () {
      final model = CompanyExpenseTripLookupModel.fromMap({
        DbCommonFields.id: _tripId,
        CompanyExpenseLookupDbFields.loadingOrderNumber: null,
        CompanyExpenseLookupDbFields.waybillNumber: null,
        CompanyExpenseLookupDbFields.customersTableName: {
          CompanyExpenseLookupDbFields.name: ' Test Customer ',
        },
        CompanyExpenseLookupDbFields.routesTableName: {
          CompanyExpenseLookupDbFields.loadingLocation: ' DUBAI ',
          CompanyExpenseLookupDbFields.unloadingLocation: ' SHARJAH ',
        },
      });

      expect(model.customerName, 'Test Customer');
      expect(model.routeLoadingLocation, 'DUBAI');
      expect(model.routeUnloadingLocation, 'SHARJAH');
      expect(model.toLinkOption().label, 'Test Customer - DUBAI -> SHARJAH');
    });
  });
}

const _tripId = '60f366ef-cb31-4e48-b249-a7d774f615bc';

CompanyExpenseTripLookupModel _model({
  String? loadingOrderNumber,
  String? waybillNumber,
  String? customerName,
  String? routeLoadingLocation,
  String? routeUnloadingLocation,
}) {
  return CompanyExpenseTripLookupModel(
    id: _tripId,
    loadingOrderNumber: loadingOrderNumber,
    waybillNumber: waybillNumber,
    customerName: customerName,
    routeLoadingLocation: routeLoadingLocation,
    routeUnloadingLocation: routeUnloadingLocation,
  );
}
