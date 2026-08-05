import '../../../../core/domain/value_objects/money.dart';
import '../../../trips/domain/entities/trip_status.dart';

final class BillableTrip {
  final String id;
  final String companyId;
  final String customerId;
  final TripStatus status;
  final Money freightAmount;
  final bool isAlreadyInvoiced;
  final String? loadingOrderNumber;
  final String? waybillNumber;
  final DateTime? serviceDate;
  final double? quantityTons;

  const BillableTrip({
    required this.id,
    required this.companyId,
    required this.customerId,
    required this.status,
    required this.freightAmount,
    required this.isAlreadyInvoiced,
    this.loadingOrderNumber,
    this.waybillNumber,
    this.serviceDate,
    this.quantityTons,
  });
}
