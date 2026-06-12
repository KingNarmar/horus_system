import '../../domain/entities/driver.dart';
import '../../domain/entities/driver_write_data.dart';
import '../models/driver_model.dart';

extension DriverModelMapper on DriverModel {
  Driver toEntity() {
    return Driver(
      id: id,
      companyId: companyId,
      fullName: fullName,
      phone: phone,
      nationalId: nationalId,
      licenseNumber: licenseNumber,
      licenseExpiryDate: licenseExpiryDate,
      notes: notes,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

extension DriverAuditMapper on DriverModel {
  Map<String, Object?> toAuditValues() {
    return {
      'id': id,
      'company_id': companyId,
      'full_name': fullName,
      'phone': phone,
      'national_id': nationalId,
      'license_number': licenseNumber,
      'license_expiry_date': licenseExpiryDate?.toUtc().toIso8601String(),
      'notes': notes,
      'is_active': isActive,
      'created_at': createdAt?.toUtc().toIso8601String(),
      'updated_at': updatedAt?.toUtc().toIso8601String(),
    };
  }
}

extension DriverWriteDataMapper on DriverWriteData {
  Map<String, dynamic> toInsertMap() {
    return {
      'company_id': companyId,
      'full_name': fullName,
      'phone': phone,
      'national_id': nationalId,
      'license_number': licenseNumber,
      'license_expiry_date': licenseExpiryDate?.toUtc().toIso8601String(),
      'notes': notes,
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'full_name': fullName,
      'phone': phone,
      'national_id': nationalId,
      'license_number': licenseNumber,
      'license_expiry_date': licenseExpiryDate?.toUtc().toIso8601String(),
      'notes': notes,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }
}
