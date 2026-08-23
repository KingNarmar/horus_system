import '../../../../core/data/constants/db_common_fields.dart';
import '../../../../core/data/utils/db_timestamp.dart';
import '../../domain/entities/trip_entity.dart';
import '../../domain/entities/trip_status.dart';
import '../../domain/entities/trip_status_history.dart';
import '../../domain/entities/trip_write_data.dart';
import '../constants/trip_db_fields.dart';
import '../models/trip_model.dart';
import '../models/trip_status_history_model.dart';

extension TripModelMapper on TripModel {
  TripEntity toEntity() {
    return TripEntity(
      id: id,
      companyId: companyId,
      customerId: customerId,
      routeId: routeId,
      driverId: driverId,
      tractorHeadId: tractorHeadId,
      trailerId: trailerId,
      status: TripStatusX.fromValue(status),
      loadingOrderNumber: loadingOrderNumber,
      waybillNumber: waybillNumber,
      quantityTons: quantityTons,
      freightPrice: freightPrice,
      totalExpenses: totalExpenses,
      scheduledLoadingAt: scheduledLoadingAt,
      scheduledDeliveryAt: scheduledDeliveryAt,
      actualLoadingAt: actualLoadingAt,
      actualDeliveryAt: actualDeliveryAt,
      notes: notes,
      customerName: customerName,
      routeName: routeName,
      driverName: driverName,
      tractorHeadPlateNumber: tractorHeadPlateNumber,
      trailerPlateNumber: trailerPlateNumber,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, Object?> toAuditValues() {
    return {
      DbCommonFields.id: id,
      DbCommonFields.companyId: companyId,
      TripDbFields.customerId: customerId,
      TripDbFields.routeId: routeId,
      TripDbFields.driverId: driverId,
      TripDbFields.tractorHeadId: tractorHeadId,
      TripDbFields.trailerId: trailerId,
      TripDbFields.status: status,
      TripDbFields.loadingOrderNumber: loadingOrderNumber,
      TripDbFields.waybillNumber: waybillNumber,
      TripDbFields.quantityTons: quantityTons,
      TripDbFields.freightPrice: freightPrice,
      TripDbFields.totalExpenses: totalExpenses,
      TripDbFields.scheduledLoadingAt:
          scheduledLoadingAt?.toUtc().toIso8601String(),
      TripDbFields.scheduledDeliveryAt:
          scheduledDeliveryAt?.toUtc().toIso8601String(),
      TripDbFields.actualLoadingAt:
          actualLoadingAt?.toUtc().toIso8601String(),
      TripDbFields.actualDeliveryAt:
          actualDeliveryAt?.toUtc().toIso8601String(),
      TripDbFields.notes: notes,
      TripDbFields.customerNameAlias: customerName,
      TripDbFields.routeNameAlias: routeName,
      TripDbFields.driverNameAlias: driverName,
      TripDbFields.tractorHeadPlateNumberAlias: tractorHeadPlateNumber,
      TripDbFields.trailerPlateNumberAlias: trailerPlateNumber,
      DbCommonFields.createdAt: createdAt?.toUtc().toIso8601String(),
      DbCommonFields.updatedAt: updatedAt?.toUtc().toIso8601String(),
    };
  }
}

extension TripStatusHistoryModelMapper on TripStatusHistoryModel {
  TripStatusHistory toEntity() {
    return TripStatusHistory(
      id: id,
      companyId: companyId,
      tripId: tripId,
      oldStatus: oldStatus == null ? null : TripStatusX.fromValue(oldStatus),
      newStatus: TripStatusX.fromValue(newStatus),
      changedByUserId: changedByUserId,
      changedByName: changedByName,
      changedByRole: changedByRole,
      notes: notes,
      changedAt: changedAt,
    );
  }
}

extension TripWriteDataMapper on TripWriteData {
  Map<String, dynamic> toInsertMap() {
    return {
      DbCommonFields.companyId: companyId,
      TripDbFields.customerId: customerId,
      TripDbFields.routeId: routeId,
      TripDbFields.driverId: driverId,
      TripDbFields.tractorHeadId: tractorHeadId,
      TripDbFields.trailerId: trailerId,
      TripDbFields.loadingOrderNumber: loadingOrderNumber,
      TripDbFields.waybillNumber: waybillNumber,
      TripDbFields.quantityTons: quantityTons,
      TripDbFields.freightPrice: freightPrice,
      TripDbFields.scheduledLoadingAt: _toUtcIsoString(scheduledLoadingAt),
      TripDbFields.scheduledDeliveryAt: _toUtcIsoString(scheduledDeliveryAt),
      TripDbFields.actualLoadingAt: _toUtcIsoString(actualLoadingAt),
      TripDbFields.actualDeliveryAt: _toUtcIsoString(actualDeliveryAt),
      TripDbFields.notes: notes,
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      TripDbFields.customerId: customerId,
      TripDbFields.routeId: routeId,
      TripDbFields.driverId: driverId,
      TripDbFields.tractorHeadId: tractorHeadId,
      TripDbFields.trailerId: trailerId,
      TripDbFields.loadingOrderNumber: loadingOrderNumber,
      TripDbFields.waybillNumber: waybillNumber,
      TripDbFields.quantityTons: quantityTons,
      TripDbFields.freightPrice: freightPrice,
      TripDbFields.scheduledLoadingAt: _toUtcIsoString(scheduledLoadingAt),
      TripDbFields.scheduledDeliveryAt: _toUtcIsoString(scheduledDeliveryAt),
      TripDbFields.actualLoadingAt: _toUtcIsoString(actualLoadingAt),
      TripDbFields.actualDeliveryAt: _toUtcIsoString(actualDeliveryAt),
      TripDbFields.notes: notes,
      DbCommonFields.updatedAt: DbTimestamp.nowUtcIsoString(),
    };
  }
}

extension TripStatusMapper on TripStatus {
  Map<String, dynamic> toTripStatusUpdateMap() {
    return {
      TripDbFields.status: value,
      DbCommonFields.updatedAt: DbTimestamp.nowUtcIsoString(),
    };
  }

  Map<String, dynamic> toHistoryInsertMap({
    required String companyId,
    required String tripId,
    required TripStatus? oldStatus,
    required String actorRole,
    String? notes,
  }) {
    return {
      DbCommonFields.companyId: companyId,
      TripStatusHistoryDbFields.tripId: tripId,
      TripStatusHistoryDbFields.oldStatus: oldStatus?.value,
      TripStatusHistoryDbFields.newStatus: value,
      TripStatusHistoryDbFields.changedByRole: actorRole,
      TripStatusHistoryDbFields.notes: notes,
    };
  }
}

String? _toUtcIsoString(DateTime? value) {
  return value?.toUtc().toIso8601String();
}
