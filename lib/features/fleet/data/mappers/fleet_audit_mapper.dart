import '../../../../core/data/constants/db_common_fields.dart';
import '../constants/tractor_head_db_fields.dart';
import '../constants/trailer_db_fields.dart';
import '../models/tractor_head_model.dart';
import '../models/trailer_model.dart';

extension TractorHeadAuditMapper on TractorHeadModel {
  Map<String, Object?> toAuditValues() {
    return {
      DbCommonFields.id: id,
      DbCommonFields.companyId: companyId,
      TractorHeadDbFields.plateNumber: plateNumber,
      TractorHeadDbFields.licenseExpiryDate: licenseExpiryDate?.toUtc().toIso8601String(),
      TractorHeadDbFields.status: status,
      TractorHeadDbFields.notes: notes,
      DbCommonFields.isActive: isActive,
      DbCommonFields.createdAt: createdAt?.toUtc().toIso8601String(),
      DbCommonFields.updatedAt: updatedAt?.toUtc().toIso8601String(),
    };
  }
}

extension TrailerAuditMapper on TrailerModel {
  Map<String, Object?> toAuditValues() {
    return {
      DbCommonFields.id: id,
      DbCommonFields.companyId: companyId,
      TrailerDbFields.plateNumber: plateNumber,
      TrailerDbFields.licenseExpiryDate: licenseExpiryDate?.toUtc().toIso8601String(),
      TrailerDbFields.status: status,
      TrailerDbFields.technicalNotes: technicalNotes,
      DbCommonFields.isActive: isActive,
      DbCommonFields.createdAt: createdAt?.toUtc().toIso8601String(),
      DbCommonFields.updatedAt: updatedAt?.toUtc().toIso8601String(),
    };
  }
}
