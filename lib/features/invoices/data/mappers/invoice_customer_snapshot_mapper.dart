import '../../domain/entities/invoice_customer_snapshot.dart';
import '../models/invoice_customer_snapshot_model.dart';

extension InvoiceCustomerSnapshotModelMapper on InvoiceCustomerSnapshotModel {
  InvoiceCustomerSnapshot toEntity() {
    return InvoiceCustomerSnapshot(
      companyId: companyId,
      customerId: customerId,
      name: name,
      taxRegistrationNumber: taxRegistrationNumber,
      address: address,
      city: city,
      country: country,
    );
  }
}
