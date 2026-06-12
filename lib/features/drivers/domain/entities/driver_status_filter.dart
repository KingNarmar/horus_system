import 'driver.dart';

enum DriverStatusFilter { active, inactive, all }

extension DriverStatusFilterX on DriverStatusFilter {
  bool matches(Driver driver) {
    return switch (this) {
      DriverStatusFilter.active => driver.isActive,
      DriverStatusFilter.inactive => !driver.isActive,
      DriverStatusFilter.all => true,
    };
  }
}
