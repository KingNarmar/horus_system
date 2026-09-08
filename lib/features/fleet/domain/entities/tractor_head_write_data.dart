import '../../../../core/domain/value_objects/business_date.dart';
import 'vehicle_status.dart';

class TractorHeadWriteData {
  final String companyId;
  final String plateNumber;
  final VehicleStatus status;
  final BusinessDate? licenseExpiryDate;
  final double? expectedFuelConsumption;
  final String? notes;

  const TractorHeadWriteData({
    required this.companyId,
    required this.plateNumber,
    required this.status,
    this.licenseExpiryDate,
    this.expectedFuelConsumption,
    this.notes,
  });
}
