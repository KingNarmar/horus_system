import 'trip_lookup_option.dart';

class TripFormLookups {
  final List<TripLookupOption> customers;
  final List<TripLookupOption> routes;
  final List<TripLookupOption> drivers;
  final List<TripLookupOption> tractorHeads;
  final List<TripLookupOption> trailers;

  const TripFormLookups({
    required this.customers,
    required this.routes,
    required this.drivers,
    required this.tractorHeads,
    required this.trailers,
  });

  bool get hasRequiredLookups {
    return customers.isNotEmpty && routes.isNotEmpty;
  }
}
