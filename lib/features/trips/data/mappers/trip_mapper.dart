import '../../../../core/data/constants/db_common_fields.dart';
import '../../../../core/data/utils/db_timestamp.dart';
import '../../domain/entities/trip_entity.dart';
import '../../domain/entities/trip_status.dart';
import '../../domain/entities/trip_status_history.dart';
import '../../domain/entities/trip_write_data.dart';
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
      'customer_id': customerId,
      'route_id': routeId,
      'driver_id': driverId,
      'tractor_head_id': tractorHeadId,
      'trailer_id': trailerId,
      'status': status,
      'loading_order_number': loadingOrderNumber,
      'waybill_number': waybillNumber,
      'quantity_tons': quantityTons,
      'freight_price': freightPrice,
      'total_expenses': totalExpenses,
      'scheduled_loading_at': scheduledLoadingAt?.toUtc().toIso8601String(),
      'scheduled_delivery_at': scheduledDeliveryAt?.toUtc().toIso8601String(),
      'actual_loading_at': actualLoadingAt?.toUtc().toIso8601String(),
      'actual_delivery_at': actualDeliveryAt?.toUtc().toIso8601String(),
      'notes': notes,
      'customer_name': customerName,
      'route_name': routeName,
      'driver_name': driverName,
      'tractor_head_plate_number': tractorHeadPlateNumber,
      'trailer_plate_number': trailerPlateNumber,
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
      'customer_id': customerId,
      'route_id': routeId,
      'driver_id': driverId,
      'tractor_head_id': tractorHeadId,
      'trailer_id': trailerId,
      'loading_order_number': loadingOrderNumber,
      'waybill_number': waybillNumber,
      'quantity_tons': quantityTons,
      'freight_price': freightPrice,
      'scheduled_loading_at': _toUtcIsoString(scheduledLoadingAt),
      'scheduled_delivery_at': _toUtcIsoString(scheduledDeliveryAt),
      'actual_loading_at': _toUtcIsoString(actualLoadingAt),
      'actual_delivery_at': _toUtcIsoString(actualDeliveryAt),
      'notes': notes,
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'customer_id': customerId,
      'route_id': routeId,
      'driver_id': driverId,
      'tractor_head_id': tractorHeadId,
      'trailer_id': trailerId,
      'loading_order_number': loadingOrderNumber,
      'waybill_number': waybillNumber,
      'quantity_tons': quantityTons,
      'freight_price': freightPrice,
      'scheduled_loading_at': _toUtcIsoString(scheduledLoadingAt),
      'scheduled_delivery_at': _toUtcIsoString(scheduledDeliveryAt),
      'actual_loading_at': _toUtcIsoString(actualLoadingAt),
      'actual_delivery_at': _toUtcIsoString(actualDeliveryAt),
      'notes': notes,
      DbCommonFields.updatedAt: DbTimestamp.nowUtcIsoString(),
    };
  }
}

extension TripStatusMapper on TripStatus {
  Map<String, dynamic> toTripStatusUpdateMap() {
    return {
      'status': value,
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
      'trip_id': tripId,
      'old_status': oldStatus?.value,
      'new_status': value,
      'changed_by_role': actorRole,
      'notes': notes,
    };
  }
}

String? _toUtcIsoString(DateTime? value) {
  return value?.toUtc().toIso8601String();
}
