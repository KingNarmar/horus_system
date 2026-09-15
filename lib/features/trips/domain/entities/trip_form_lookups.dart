import 'trip_lookup_option.dart';
import 'trip_route_lookup_option.dart';

class TripFormLookups {
  final List<TripLookupOption> customers;
  final List<TripRouteLookupOption> routes;
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

  TripRouteLookupOption? routeById(String? id) {
    if (id == null) return null;
    for (final route in routes) {
      if (route.id == id) return route;
    }
    return null;
  }
}
