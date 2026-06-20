import 'trip_status.dart';

enum TripStatusFilter {
  all,
  open,
  created,
  assigned,
  loaded,
  onRoad,
  arrived,
  delivered,
  documentsReceived,
  invoiced,
  paid,
  cancelled,
}

extension TripStatusFilterX on TripStatusFilter {
  bool matches(TripStatus status) {
    return switch (this) {
      TripStatusFilter.all => true,
      TripStatusFilter.open => status.blocksVehicleAssignment,
      TripStatusFilter.created => status == TripStatus.created,
      TripStatusFilter.assigned => status == TripStatus.assigned,
      TripStatusFilter.loaded => status == TripStatus.loaded,
      TripStatusFilter.onRoad => status == TripStatus.onRoad,
      TripStatusFilter.arrived => status == TripStatus.arrived,
      TripStatusFilter.delivered => status == TripStatus.delivered,
      TripStatusFilter.documentsReceived =>
        status == TripStatus.documentsReceived,
      TripStatusFilter.invoiced => status == TripStatus.invoiced,
      TripStatusFilter.paid => status == TripStatus.paid,
      TripStatusFilter.cancelled => status == TripStatus.cancelled,
    };
  }
}
