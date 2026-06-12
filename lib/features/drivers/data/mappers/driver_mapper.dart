import '../../domain/entities/driver.dart';
import '../../domain/entities/driver_write_data.dart';
import '../models/driver_model.dart';
import '../../../../core/data/constants/db_common_fields.dart';
import '../../../../core/data/utils/db_timestamp.dart';
import '../constants/driver_db_fields.dart';

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
      DbCommonFields.id: id,
      DbCommonFields.companyId: companyId,
      DriverDbFields.fullName: fullName,
      DriverDbFields.phone: phone,
      DriverDbFields.nationalId: nationalId,
      DriverDbFields.licenseNumber: licenseNumber,
      DriverDbFields.licenseExpiryDate: licenseExpiryDate?.toUtc().toIso8601String(),
      DriverDbFields.notes: notes,
      DbCommonFields.isActive: isActive,
      DbCommonFields.createdAt: createdAt?.toUtc().toIso8601String(),
      DbCommonFields.updatedAt: updatedAt?.toUtc().toIso8601String(),
    };
  }
}

extension DriverWriteDataMapper on DriverWriteData {
  Map<String, dynamic> toInsertMap() {
    return {
      DbCommonFields.companyId: companyId,
      DriverDbFields.fullName: fullName,
      DriverDbFields.phone: phone,
      DriverDbFields.nationalId: nationalId,
      DriverDbFields.licenseNumber: licenseNumber,
      DriverDbFields.licenseExpiryDate: licenseExpiryDate?.toUtc().toIso8601String(),
      DriverDbFields.notes: notes,
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      DriverDbFields.fullName: fullName,
      DriverDbFields.phone: phone,
      DriverDbFields.nationalId: nationalId,
      DriverDbFields.licenseNumber: licenseNumber,
      DriverDbFields.licenseExpiryDate: licenseExpiryDate?.toUtc().toIso8601String(),
      DriverDbFields.notes: notes,
      DbCommonFields.updatedAt: DbTimestamp.nowUtcIsoString(),
    };
  }
}
