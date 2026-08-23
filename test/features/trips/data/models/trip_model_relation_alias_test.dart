import 'package:horus_system/features/trips/data/models/trip_model.dart';
import 'package:test/test.dart';

void main() {
  test('TripModel preserves direct display-name aliases over nested relations', () {
    final model = TripModel.fromMap({
      'id': 'trip-alias',
      'company_id': 'company-1',
      'customer_id': 'customer-1',
      'route_id': 'route-1',
      'status': 'created',
      'customer_name': 'Alias Customer',
      'route_name': 'Alias Route',
      'driver_name': 'Alias Driver',
      'tractor_head_plate_number': 'Alias TH',
      'trailer_plate_number': 'Alias TR',
      'customers': {'name': 'Nested Customer'},
      'routes': {
        'loading_location': 'Nested Loading',
        'unloading_location': 'Nested Unloading',
      },
      'drivers': {'full_name': 'Nested Driver'},
      'tractor_heads': {'plate_number': 'Nested TH'},
      'trailers': {'plate_number': 'Nested TR'},
    });

    expect(model.customerName, 'Alias Customer');
    expect(model.routeName, 'Alias Route');
    expect(model.driverName, 'Alias Driver');
    expect(model.tractorHeadPlateNumber, 'Alias TH');
    expect(model.trailerPlateNumber, 'Alias TR');
  });
}
