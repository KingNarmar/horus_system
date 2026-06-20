class TripWriteData {
  final String companyId;
  final String customerId;
  final String routeId;
  final String? driverId;
  final String? tractorHeadId;
  final String? trailerId;
  final String? loadingOrderNumber;
  final String? waybillNumber;
  final double? quantityTons;
  final double? freightPrice;
  final DateTime? scheduledLoadingAt;
  final DateTime? scheduledDeliveryAt;
  final DateTime? actualLoadingAt;
  final DateTime? actualDeliveryAt;
  final String? notes;

  const TripWriteData({
    required this.companyId,
    required this.customerId,
    required this.routeId,
    this.driverId,
    this.tractorHeadId,
    this.trailerId,
    this.loadingOrderNumber,
    this.waybillNumber,
    this.quantityTons,
    this.freightPrice,
    this.scheduledLoadingAt,
    this.scheduledDeliveryAt,
    this.actualLoadingAt,
    this.actualDeliveryAt,
    this.notes,
  });
}
