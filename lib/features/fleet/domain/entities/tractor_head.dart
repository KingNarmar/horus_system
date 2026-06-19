import 'vehicle_status.dart';

class TractorHead {
  final String id;
  final String companyId;
  final String plateNumber;
  final VehicleStatus status;
  final bool isActive;
  final DateTime? licenseExpiryDate;
  final double? expectedFuelConsumption;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const TractorHead({
    required this.id,
    required this.companyId,
    required this.plateNumber,
    required this.status,
    required this.isActive,
    this.licenseExpiryDate,
    this.expectedFuelConsumption,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });
}
