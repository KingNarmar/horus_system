import '../../../../core/data/constants/db_common_fields.dart';

abstract final class TripDbFields {
  static const tableName = 'trips';

  static const customerId = 'customer_id';
  static const routeId = 'route_id';
  static const driverId = 'driver_id';
  static const tractorHeadId = 'tractor_head_id';
  static const trailerId = 'trailer_id';
  static const status = 'status';
  static const loadingOrderNumber = 'loading_order_number';
  static const waybillNumber = 'waybill_number';
  static const quantityTons = 'quantity_tons';
  static const freightPrice = 'freight_price';
  static const totalExpenses = 'total_expenses';
  static const scheduledLoadingAt = 'scheduled_loading_at';
  static const scheduledDeliveryAt = 'scheduled_delivery_at';
  static const actualLoadingAt = 'actual_loading_at';
  static const actualDeliveryAt = 'actual_delivery_at';
  static const notes = 'notes';

  static const customerNameAlias = 'customer_name';
  static const routeNameAlias = 'route_name';
  static const driverNameAlias = 'driver_name';
  static const tractorHeadPlateNumberAlias = 'tractor_head_plate_number';
  static const trailerPlateNumberAlias = 'trailer_plate_number';

  static const customerRelationKey = 'customer';
  static const routeRelationKey = 'route';
  static const driverRelationKey = 'driver';
  static const tractorHeadRelationKey = 'tractor_head';
  static const trailerRelationKey = 'trailer';

  static const openTripStatusFilter =
      '$status.eq.created,$status.eq.assigned,$status.eq.loaded,'
      '$status.eq.on_road,$status.eq.arrived';

  static const allColumns =
      '${DbCommonFields.id}, ${DbCommonFields.companyId}, $customerId, $routeId, '
      '$driverId, $tractorHeadId, $trailerId, $status, $loadingOrderNumber, '
      '$waybillNumber, $quantityTons, $freightPrice, $totalExpenses, '
      '$scheduledLoadingAt, $scheduledDeliveryAt, $actualLoadingAt, '
      '$actualDeliveryAt, $notes, ${DbCommonFields.createdAt}, '
      '${DbCommonFields.updatedAt}, '
      '${TripLookupDbFields.customersTableName}!trips_company_customer_fk'
      '(${TripLookupDbFields.name}), '
      '${TripLookupDbFields.routesTableName}!trips_company_route_fk'
      '(${TripLookupDbFields.loadingLocation}, '
      '${TripLookupDbFields.unloadingLocation}), '
      '${TripLookupDbFields.driversTableName}!trips_company_driver_fk'
      '(${TripLookupDbFields.fullName}), '
      '${TripLookupDbFields.tractorHeadsTableName}!trips_company_tractor_fk'
      '(${TripLookupDbFields.plateNumber}), '
      '${TripLookupDbFields.trailersTableName}!trips_company_trailer_fk'
      '(${TripLookupDbFields.plateNumber})';
}

abstract final class TripStatusHistoryDbFields {
  static const tableName = 'trip_status_history';

  static const tripId = 'trip_id';
  static const oldStatus = 'old_status';
  static const newStatus = 'new_status';
  static const changedBy = 'changed_by';
  static const changedByName = 'changed_by_name';
  static const changedByRole = 'changed_by_role';
  static const notes = 'notes';
  static const changedAt = 'changed_at';

  static const allColumns =
      '${DbCommonFields.id}, ${DbCommonFields.companyId}, $tripId, $oldStatus, '
      '$newStatus, $changedBy, $changedByName, $changedByRole, $notes, '
      '$changedAt';
}

abstract final class TripLookupDbFields {
  static const customersTableName = 'customers';
  static const routesTableName = 'routes';
  static const driversTableName = 'drivers';
  static const tractorHeadsTableName = 'tractor_heads';
  static const trailersTableName = 'trailers';

  static const name = 'name';
  static const fullName = 'full_name';
  static const plateNumber = 'plate_number';
  static const loadingLocation = 'loading_location';
  static const unloadingLocation = 'unloading_location';

  static const routeColumns =
      '${DbCommonFields.id}, $loadingLocation, $unloadingLocation';
}
