import 'customer.dart';

enum CustomerStatusFilter { active, inactive, all }

extension CustomerStatusFilterX on CustomerStatusFilter {
  bool matches(Customer customer) {
    return switch (this) {
      CustomerStatusFilter.active => customer.isActive,
      CustomerStatusFilter.inactive => !customer.isActive,
      CustomerStatusFilter.all => true,
    };
  }
}
