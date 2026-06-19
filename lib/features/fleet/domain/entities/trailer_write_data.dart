import 'vehicle_status.dart';

class TrailerWriteData {
  final String companyId;
  final String plateNumber;
  final VehicleStatus status;
  final DateTime? licenseExpiryDate;
  final String? technicalNotes;

  const TrailerWriteData({
    required this.companyId,
    required this.plateNumber,
    required this.status,
    this.licenseExpiryDate,
    this.technicalNotes,
  });
}
