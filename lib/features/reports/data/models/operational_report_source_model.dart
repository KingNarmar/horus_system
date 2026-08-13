import 'report_model_parsing.dart';
import 'report_source_metadata_model.dart';

final class OperationalReportSourceModel {
  final ReportSourceMetadataModel metadata;
  final List<OperationalTripRowModel> rows;

  OperationalReportSourceModel({
    required this.metadata,
    required List<OperationalTripRowModel> rows,
  }) : rows = List.unmodifiable(rows);

  factory OperationalReportSourceModel.fromMap(Map<String, dynamic> map) {
    return OperationalReportSourceModel(
      metadata: ReportSourceMetadataModel.fromRoot(map),
      rows: requiredMapList(map['rows'], 'rows')
          .map(OperationalTripRowModel.fromMap)
          .toList(growable: false),
    );
  }
}

final class OperationalTripRowModel {
  final String tripId;
  final String? tripNumber;
  final DateTime operationalDate;
  final String status;
  final String customerId;
  final String customerName;
  final String? driverId;
  final String? driverName;
  final String? tractorHeadId;
  final String? tractorHeadPlateNumber;
  final String? trailerId;
  final String? trailerPlateNumber;
  final String routeId;
  final String loadingLocation;
  final String unloadingLocation;
  final String? loadingOrderNumber;
  final String? waybillNumber;
  final String? cargoType;
  final double? quantityTons;

  const OperationalTripRowModel({
    required this.tripId,
    required this.tripNumber,
    required this.operationalDate,
    required this.status,
    required this.customerId,
    required this.customerName,
    required this.driverId,
    required this.driverName,
    required this.tractorHeadId,
    required this.tractorHeadPlateNumber,
    required this.trailerId,
    required this.trailerPlateNumber,
    required this.routeId,
    required this.loadingLocation,
    required this.unloadingLocation,
    required this.loadingOrderNumber,
    required this.waybillNumber,
    required this.cargoType,
    required this.quantityTons,
  });

  factory OperationalTripRowModel.fromMap(Map<String, dynamic> map) {
    return OperationalTripRowModel(
      tripId: requiredString(map['trip_id'], 'trip_id'),
      tripNumber: optionalString(map['trip_number'], 'trip_number'),
      operationalDate: requiredDate(
        map['operational_date'],
        'operational_date',
      ),
      status: requiredString(map['status'], 'status'),
      customerId: requiredString(map['customer_id'], 'customer_id'),
      customerName: requiredString(map['customer_name'], 'customer_name'),
      driverId: optionalString(map['driver_id'], 'driver_id'),
      driverName: optionalString(map['driver_name'], 'driver_name'),
      tractorHeadId: optionalString(map['tractor_head_id'], 'tractor_head_id'),
      tractorHeadPlateNumber: optionalString(
        map['tractor_head_plate_number'],
        'tractor_head_plate_number',
      ),
      trailerId: optionalString(map['trailer_id'], 'trailer_id'),
      trailerPlateNumber: optionalString(
        map['trailer_plate_number'],
        'trailer_plate_number',
      ),
      routeId: requiredString(map['route_id'], 'route_id'),
      loadingLocation: requiredString(
        map['loading_location'],
        'loading_location',
      ),
      unloadingLocation: requiredString(
        map['unloading_location'],
        'unloading_location',
      ),
      loadingOrderNumber: optionalString(
        map['loading_order_number'],
        'loading_order_number',
      ),
      waybillNumber: optionalString(map['waybill_number'], 'waybill_number'),
      cargoType: optionalString(map['cargo_type'], 'cargo_type'),
      quantityTons: optionalDouble(map['quantity_tons'], 'quantity_tons'),
    );
  }
}
