enum VehicleStatus {
  available,
  onTrip,
  loading,
  unloading,
  maintenance,
  stopped,
  inactive,
}

extension VehicleStatusX on VehicleStatus {
  String get value {
    return switch (this) {
      VehicleStatus.available => 'available',
      VehicleStatus.onTrip => 'on_trip',
      VehicleStatus.loading => 'loading',
      VehicleStatus.unloading => 'unloading',
      VehicleStatus.maintenance => 'maintenance',
      VehicleStatus.stopped => 'stopped',
      VehicleStatus.inactive => 'inactive',
    };
  }

  bool get isActive => this != VehicleStatus.inactive;

  static VehicleStatus fromValue(String? value) {
    return VehicleStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => VehicleStatus.available,
    );
  }
}
