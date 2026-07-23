import 'driver.dart';
import 'driver_status.dart';

enum DriverStatusFilter { active, inactive, all }

extension DriverStatusFilterX on DriverStatusFilter {
  bool matches(Driver driver) {
    if (this == DriverStatusFilter.all) return true;
    if (this == DriverStatusFilter.active) {
      return driver.status == DriverStatus.active;
    }
    return driver.status == DriverStatus.inactive;
  }
}
