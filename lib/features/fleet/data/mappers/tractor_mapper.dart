import '../../../../core/data/constants/db_common_fields.dart';
import '../../../../core/data/utils/db_timestamp.dart';
import '../../domain/entities/tractor_head.dart';
import '../../domain/entities/tractor_head_write_data.dart';
import '../../domain/entities/vehicle_status.dart';
import '../constants/tractor_head_db_fields.dart';
import '../models/tractor_head_model.dart';

extension TractorHeadModelMapper on TractorHeadModel {
  TractorHead toEntity() {
    return TractorHead(
      id: id,
      companyId: companyId,
      plateNumber: plateNumber,
      status: VehicleStatusX.fromValue(status),
      isActive: isActive,
      licenseExpiryDate: licenseExpiryDate,
      notes: notes,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

extension TractorHeadWriteDataMapper on TractorHeadWriteData {
  Map<String, dynamic> toInsertMap() {
    return {
      DbCommonFields.companyId: companyId,
      TractorHeadDbFields.plateNumber: plateNumber,
      TractorHeadDbFields.licenseExpiryDate: licenseExpiryDate?.toUtc().toIso8601String(),
      TractorHeadDbFields.status: status.value,
      TractorHeadDbFields.notes: notes,
      DbCommonFields.isActive: status.isActive,
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      TractorHeadDbFields.plateNumber: plateNumber,
      TractorHeadDbFields.licenseExpiryDate: licenseExpiryDate?.toUtc().toIso8601String(),
      TractorHeadDbFields.status: status.value,
      TractorHeadDbFields.notes: notes,
      DbCommonFields.isActive: status.isActive,
      DbCommonFields.updatedAt: DbTimestamp.nowUtcIsoString(),
    };
  }
}
