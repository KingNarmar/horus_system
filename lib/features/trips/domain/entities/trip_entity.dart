import 'trip_status.dart';

class TripEntity {
  final String id;
  final String companyId;
  final String customerId;
  final String routeId;
  final String? driverId;
  final String? tractorHeadId;
  final String? trailerId;
  final TripStatus status;
  final String? loadingOrderNumber;
  final String? waybillNumber;
  final double? quantityTons;
  final double? freightPrice;
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
    required this.customerId,
    required this.routeId,
    required this.status,
    this.driverId,
    this.tractorHeadId,
    this.trailerId,
    this.loadingOrderNumber,
    this.waybillNumber,
    this.quantityTons,
    this.freightPrice,
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

  double get netProfit {
    return (freightPrice ?? 0) - (totalExpenses ?? 0);
  }

  String get displayName {
    final orderNumber = _textOrNull(loadingOrderNumber);
    if (orderNumber != null) return orderNumber;

    final waybill = _textOrNull(waybillNumber);
    if (waybill != null) return waybill;

    final customer = _textOrNull(customerName);
    final route = _textOrNull(routeName);

    if (customer != null && route != null) {
      return '$customer - $route';
    }

    if (customer != null) return customer;
    if (route != null) return route;

    return 'Trip';
  }
}

String? _textOrNull(String? value) {
  final text = value?.trim();
  if (text == null || text.isEmpty) return null;
  return text;
}
