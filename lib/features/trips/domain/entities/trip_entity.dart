import '../../../../core/domain/value_objects/money.dart';
import '../value_objects/quantity_tons.dart';
import '../value_objects/trip_number.dart';
import 'trip_status.dart';

class TripEntity {
  final String id;
  final String companyId;
  final TripNumber tripNumber;
  final String customerId;
  final String routeId;
  final String? driverId;
  final String? tractorHeadId;
  final String? trailerId;
  final TripStatus status;
  final String? loadingOrderNumber;
  final String? waybillNumber;
  final QuantityTons? quantityTons;
  final Money? agreedFreightRatePerTon;
  final Money? commercialAmount;
  final double? totalExpenses;
  final DateTime? scheduledLoadingAt;
  final DateTime? scheduledDeliveryAt;
  final DateTime? actualLoadingAt;
  final DateTime? actualDeliveryAt;
  final String? notes;
  final String? customerName;
  final String? routeName;
  final String? driverName;
  final String? tractorHeadPlateNumber;
  final String? trailerPlateNumber;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const TripEntity({
    required this.id,
    required this.companyId,
    required this.tripNumber,
    required this.customerId,
    required this.routeId,
    required this.status,
    this.driverId,
    this.tractorHeadId,
    this.trailerId,
    this.loadingOrderNumber,
    this.waybillNumber,
    this.quantityTons,
    this.agreedFreightRatePerTon,
    this.commercialAmount,
    this.totalExpenses,
    this.scheduledLoadingAt,
    this.scheduledDeliveryAt,
    this.actualLoadingAt,
    this.actualDeliveryAt,
    this.notes,
    this.customerName,
    this.routeName,
    this.driverName,
    this.tractorHeadPlateNumber,
    this.trailerPlateNumber,
    this.createdAt,
    this.updatedAt,
  });

  bool get isVehicleAssignmentBlocking => status.blocksVehicleAssignment;

  bool get hasAuthoritativeCommercialSnapshot {
    return quantityTons != null &&
        agreedFreightRatePerTon != null &&
        commercialAmount != null;
  }

  bool get hasLegacyCommercialAmount {
    return commercialAmount != null && agreedFreightRatePerTon == null;
  }

  String get displayName => tripNumber.value;
}
