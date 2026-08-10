import '../../../../core/domain/value_objects/money.dart';
import 'billable_trip.dart';

final class InvoiceTripLine {
  final String tripId;
  final String? tripNumber;
  final String? loadingLocation;
  final String? unloadingLocation;
  final String? loadingOrderNumber;
  final String? waybillNumber;
  final DateTime? serviceDate;
  final double? quantityTons;
  final Money amount;

  const InvoiceTripLine({
    required this.tripId,
    this.tripNumber,
    this.loadingLocation,
    this.unloadingLocation,
    this.loadingOrderNumber,
    this.waybillNumber,
    this.serviceDate,
    this.quantityTons,
    required this.amount,
  });

  factory InvoiceTripLine.fromBillableTrip(BillableTrip trip) {
    return InvoiceTripLine(
      tripId: trip.id,
      tripNumber: trip.tripNumber,
      loadingLocation: trip.loadingLocation,
      unloadingLocation: trip.unloadingLocation,
      loadingOrderNumber: trip.loadingOrderNumber,
      waybillNumber: trip.waybillNumber,
      serviceDate: trip.serviceDate,
      quantityTons: trip.quantityTons,
      amount: trip.freightAmount,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is InvoiceTripLine &&
            other.tripId == tripId &&
            other.tripNumber == tripNumber &&
            other.loadingLocation == loadingLocation &&
            other.unloadingLocation == unloadingLocation &&
            other.loadingOrderNumber == loadingOrderNumber &&
            other.waybillNumber == waybillNumber &&
            other.serviceDate == serviceDate &&
            other.quantityTons == quantityTons &&
            other.amount == amount;
  }

  @override
  int get hashCode => Object.hash(
    tripId,
    tripNumber,
    loadingLocation,
    unloadingLocation,
    loadingOrderNumber,
    waybillNumber,
    serviceDate,
    quantityTons,
    amount,
  );
}
