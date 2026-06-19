enum VehicleStatusFilter { active, inactive, all }

extension VehicleStatusFilterX on VehicleStatusFilter {
  bool matches(bool isActive) {
    return switch (this) {
      VehicleStatusFilter.active => isActive,
      VehicleStatusFilter.inactive => !isActive,
      VehicleStatusFilter.all => true,
    };
  }
}
