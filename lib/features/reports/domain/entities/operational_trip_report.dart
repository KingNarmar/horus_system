import '../../../trips/domain/entities/trip_status.dart';
import 'report_source_metadata.dart';

enum OperationalReportDimension { day, customer, driver, tractorHead, trailer }

final class OperationalTripReportRow {
  final String tripId;
  final String? tripNumber;
  final DateTime operationalDate;
  final TripStatus status;
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

  const OperationalTripReportRow({
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
}

final class OperationalTripReportSource {
  final ReportSourceMetadata metadata;
  final List<OperationalTripReportRow> rows;

  OperationalTripReportSource({
    required this.metadata,
    required List<OperationalTripReportRow> rows,
  }) : rows = List.unmodifiable(rows);
}

final class OperationalTripReportGroup {
  final DateTime? date;
  final String? entityId;
  final String? entityLabel;
  final List<OperationalTripReportRow> rows;

  OperationalTripReportGroup({
    required this.date,
    required this.entityId,
    required this.entityLabel,
    required List<OperationalTripReportRow> rows,
  }) : rows = List.unmodifiable(rows);

  int get tripCount => rows.length;
}

final class OperationalTripReport {
  final ReportSourceMetadata metadata;
  final OperationalReportDimension dimension;
  final List<OperationalTripReportGroup> groups;

  OperationalTripReport({
    required this.metadata,
    required this.dimension,
    required List<OperationalTripReportGroup> groups,
  }) : groups = List.unmodifiable(groups);

  int get totalTrips => groups.fold(0, (sum, group) => sum + group.tripCount);
}
