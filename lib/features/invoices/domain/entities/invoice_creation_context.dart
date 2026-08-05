import 'billable_trip.dart';
import 'invoice_customer_snapshot.dart';

final class InvoiceCreationContext {
  final InvoiceCustomerSnapshot customer;
  final bool isCustomerActive;
  final List<BillableTrip> trips;

  InvoiceCreationContext({
    required this.customer,
    required this.isCustomerActive,
    required List<BillableTrip> trips,
  }) : trips = List.unmodifiable(trips);
}
