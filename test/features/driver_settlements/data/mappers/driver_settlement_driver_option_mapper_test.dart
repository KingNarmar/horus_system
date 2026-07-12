import 'package:horus_system/features/driver_settlements/data/mappers/driver_settlement_driver_option_mapper.dart';
import 'package:horus_system/features/driver_settlements/data/models/driver_settlement_driver_option_model.dart';
import 'package:test/test.dart';

void main() {
  test('maps driver option model to pure domain entity', () {
    const model = DriverSettlementDriverOptionModel(
      id: 'driver-1',
      displayName: 'Driver One',
      isActive: false,
    );

    final entity = model.toEntity();

    expect(entity.id, 'driver-1');
    expect(entity.displayName, 'Driver One');
    expect(entity.isActive, isFalse);
  });
}
