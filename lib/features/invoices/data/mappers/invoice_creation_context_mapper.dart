import '../../domain/entities/invoice_creation_context.dart';
import '../models/invoice_creation_context_model.dart';
import 'billable_trip_mapper.dart';
import 'invoice_customer_snapshot_mapper.dart';

extension InvoiceCreationContextModelMapper on InvoiceCreationContextModel {
  InvoiceCreationContext toEntity() {
    final customerEntity = customer.toEntity();
    final tripEntities = trips.map((trip) => trip.toEntity()).toList();

    if (tripEntities.any(
      (trip) => trip.companyId != customerEntity.companyId,
    )) {
      throw const FormatException(
        'Invoice creation context contains a tenant mismatch.',
      );
    }

    return InvoiceCreationContext(
      customer: customerEntity,
      isCustomerActive: isCustomerActive,
      trips: tripEntities,
    );
  }
}
