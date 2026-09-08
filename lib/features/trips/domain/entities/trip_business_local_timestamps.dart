import '../../../../core/domain/value_objects/business_local_date_time.dart';

final class TripBusinessLocalTimestamps {
  final BusinessLocalDateTime? scheduledLoadingAt;
  final BusinessLocalDateTime? scheduledDeliveryAt;
  final BusinessLocalDateTime? actualLoadingAt;
  final BusinessLocalDateTime? actualDeliveryAt;

  const TripBusinessLocalTimestamps({
    this.scheduledLoadingAt,
    this.scheduledDeliveryAt,
    this.actualLoadingAt,
    this.actualDeliveryAt,
  });
}
