import 'driver_status.dart';

class Driver {
  final String id;
  final String companyId;
  final String fullName;
  final String? phone;
  final String? nationalId;
  final String? licenseNumber;
  final DateTime? licenseExpiryDate;
  final String? profileImagePath;
  final String? licenseImagePath;
  final String? licenseBackImagePath;
  final String? nationalIdImagePath;
  final String? nationalIdBackImagePath;
  final String? notes;
  final DriverStatus status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Driver({
    required this.id,
    required this.companyId,
    required this.fullName,
    required this.status,
    this.phone,
    this.nationalId,
    this.licenseNumber,
    this.licenseExpiryDate,
    this.profileImagePath,
    this.licenseImagePath,
    this.licenseBackImagePath,
    this.nationalIdImagePath,
    this.nationalIdBackImagePath,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });
}
