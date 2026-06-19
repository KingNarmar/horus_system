import 'vehicle_status.dart';

class TrailerEntity {
  final String id;
  final String companyId;
  final String plateNumber;
  final VehicleStatus status;
  final bool isActive;
  final DateTime? licenseExpiryDate;
  final String? technicalNotes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const TrailerEntity({
    required this.id,
    required this.companyId,
    required this.plateNumber,
    required this.status,
    required this.isActive,
    this.licenseExpiryDate,
    this.technicalNotes,
    this.createdAt,
    this.updatedAt,
  });
}
