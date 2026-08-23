import '../../../../core/data/constants/db_common_fields.dart';
import '../../../../core/data/utils/db_timestamp.dart';
import '../../domain/entities/route_entity.dart';
import '../../domain/entities/route_write_data.dart';
import '../constants/route_db_fields.dart';
import '../models/route_model.dart';

extension RouteModelMapper on RouteModel {
  RouteEntity toEntity() {
    return RouteEntity(
      id: id,
      companyId: companyId,
      loadingLocation: loadingLocation,
      unloadingLocation: unloadingLocation,
      governorateFrom: governorateFrom,
      governorateTo: governorateTo,
      defaultFreightPrice: defaultFreightPrice,
      notes: notes,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, Object?> toAuditValues() {
    return {
      DbCommonFields.id: id,
      DbCommonFields.companyId: companyId,
      RouteDbFields.loadingLocation: loadingLocation,
      RouteDbFields.unloadingLocation: unloadingLocation,
      RouteDbFields.governorateFrom: governorateFrom,
      RouteDbFields.governorateTo: governorateTo,
      RouteDbFields.defaultFreightPrice: defaultFreightPrice,
      RouteDbFields.notes: notes,
      DbCommonFields.isActive: isActive,
      DbCommonFields.createdAt: createdAt?.toUtc().toIso8601String(),
      DbCommonFields.updatedAt: updatedAt?.toUtc().toIso8601String(),
    };
  }
}

extension RouteWriteDataMapper on RouteWriteData {
  Map<String, dynamic> toInsertMap() {
    return {
      DbCommonFields.companyId: companyId,
      RouteDbFields.loadingLocation: loadingLocation,
      RouteDbFields.unloadingLocation: unloadingLocation,
      RouteDbFields.governorateFrom: governorateFrom,
      RouteDbFields.governorateTo: governorateTo,
      RouteDbFields.defaultFreightPrice: defaultFreightPrice,
      RouteDbFields.notes: notes,
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      RouteDbFields.loadingLocation: loadingLocation,
      RouteDbFields.unloadingLocation: unloadingLocation,
      RouteDbFields.governorateFrom: governorateFrom,
      RouteDbFields.governorateTo: governorateTo,
      RouteDbFields.defaultFreightPrice: defaultFreightPrice,
      RouteDbFields.notes: notes,
      DbCommonFields.updatedAt: DbTimestamp.nowUtcIsoString(),
    };
  }
}
