import '../../domain/entities/driver_settlement_driver_option.dart';
import '../models/driver_settlement_driver_option_model.dart';

extension DriverSettlementDriverOptionMapper
    on DriverSettlementDriverOptionModel {
  DriverSettlementDriverOption toEntity() {
    return DriverSettlementDriverOption(
      id: id,
      displayName: displayName,
      isActive: isActive,
    );
  }
}
