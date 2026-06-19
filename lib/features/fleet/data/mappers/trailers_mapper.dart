import '../../../../core/data/constants/db_common_fields.dart';
import '../../../../core/data/utils/db_timestamp.dart';
import '../../domain/entities/trailer_entity.dart';
import '../../domain/entities/trailer_write_data.dart';
import '../../domain/entities/vehicle_status.dart';
import '../constants/trailer_db_fields.dart';
import '../models/trailer_model.dart';

extension TrailerModelMapper on TrailerModel {
  TrailerEntity toEntity() {
    return TrailerEntity(
      id: id,
      companyId: companyId,
      plateNumber: plateNumber,
      status: VehicleStatusX.fromValue(status),
      isActive: isActive,
      licenseExpiryDate: licenseExpiryDate,
      technicalNotes: technicalNotes,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

extension TrailerWriteDataMapper on TrailerWriteData {
  Map<String, dynamic> toInsertMap() {
    return {
      DbCommonFields.companyId: companyId,
      TrailerDbFields.plateNumber: plateNumber,
      TrailerDbFields.licenseExpiryDate: licenseExpiryDate?.toUtc().toIso8601String(),
      TrailerDbFields.status: status.value,
      TrailerDbFields.technicalNotes: technicalNotes,
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      TrailerDbFields.plateNumber: plateNumber,
      TrailerDbFields.licenseExpiryDate: licenseExpiryDate?.toUtc().toIso8601String(),
      TrailerDbFields.status: status.value,
      TrailerDbFields.technicalNotes: technicalNotes,
      DbCommonFields.updatedAt: DbTimestamp.nowUtcIsoString(),
    };
  }
}
