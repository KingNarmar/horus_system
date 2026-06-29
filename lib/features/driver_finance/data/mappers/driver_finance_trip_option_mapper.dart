import '../../domain/entities/driver_finance_trip_option.dart';
import '../models/driver_finance_trip_option_model.dart';

extension DriverFinanceTripOptionModelX on DriverFinanceTripOptionModel {
  DriverFinanceTripOption toEntity() {
    return DriverFinanceTripOption(id: id, label: label);
  }
}
