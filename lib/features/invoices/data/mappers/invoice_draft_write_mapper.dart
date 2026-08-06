import '../../domain/entities/invoice_draft_data.dart';
import '../models/invoice_draft_write_model.dart';

extension InvoiceDraftDataWriteMapper on InvoiceDraftData {
  InvoiceDraftWriteModel toWriteModel() {
    return InvoiceDraftWriteModel(
      companyId: companyId,
      customerId: customer.customerId,
      tripIds: lines.map((line) => line.tripId).toList(growable: false),
      discountMinorUnits: totals.discount.minorUnits,
      taxRateBasisPoints: totals.taxRate.basisPoints,
      issueDate: issueDate?.value,
      dueDate: dueDate?.value,
      notes: notes,
    );
  }
}
