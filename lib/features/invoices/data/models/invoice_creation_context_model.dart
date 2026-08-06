import '../constants/invoices_db_fields.dart';
import '../utils/invoice_data_parser.dart';
import 'billable_trip_model.dart';
import 'invoice_customer_snapshot_model.dart';

final class InvoiceCreationContextModel {
  final InvoiceCustomerSnapshotModel customer;
  final bool isCustomerActive;
  final List<BillableTripModel> trips;

  InvoiceCreationContextModel({
    required this.customer,
    required this.isCustomerActive,
    required List<BillableTripModel> trips,
  }) : trips = List.unmodifiable(trips);

  factory InvoiceCreationContextModel.fromMap(
    Map<String, dynamic> map, {
    required String companyId,
  }) {
    final customerValue = map[InvoicesDbFields.customer];
    if (customerValue is! Map) {
      throw FormatException(
        'Invalid invoice field: ${InvoicesDbFields.customer}.',
      );
    }

    final activeValue = map[InvoicesDbFields.isCustomerActive];
    if (activeValue is! bool) {
      throw FormatException(
        'Invalid invoice field: ${InvoicesDbFields.isCustomerActive}.',
      );
    }

    final tripMaps = InvoiceDataParser.mapList(
      map[InvoicesDbFields.trips],
      InvoicesDbFields.trips,
    );

    return InvoiceCreationContextModel(
      customer: InvoiceCustomerSnapshotModel.fromContextMap(
        Map<String, dynamic>.from(customerValue),
        companyId: companyId,
      ),
      isCustomerActive: activeValue,
      trips: tripMaps.map(BillableTripModel.fromMap).toList(growable: false),
    );
  }
}
