import '../constants/invoices_rpc_constants.dart';

final class InvoiceDraftWriteModel {
  final String companyId;
  final String customerId;
  final List<String> tripIds;
  final int discountMinorUnits;
  final int taxRateBasisPoints;
  final DateTime? issueDate;
  final DateTime? dueDate;
  final String? notes;

  InvoiceDraftWriteModel({
    required this.companyId,
    required this.customerId,
    required List<String> tripIds,
    required this.discountMinorUnits,
    required this.taxRateBasisPoints,
    this.issueDate,
    this.dueDate,
    this.notes,
  }) : tripIds = List.unmodifiable(tripIds);

  Map<String, dynamic> createParams() {
    return {
      InvoicesRpcConstants.companyId: companyId,
      InvoicesRpcConstants.customerId: customerId,
      InvoicesRpcConstants.tripIds: tripIds,
      InvoicesRpcConstants.discountMinorUnits: discountMinorUnits,
      InvoicesRpcConstants.taxRateBasisPoints: taxRateBasisPoints,
      InvoicesRpcConstants.issueDate: _dateValue(issueDate),
      InvoicesRpcConstants.dueDate: _dateValue(dueDate),
      InvoicesRpcConstants.notes: notes,
    };
  }

  Map<String, dynamic> updateParams({required String invoiceId}) {
    return {InvoicesRpcConstants.invoiceId: invoiceId, ...createParams()};
  }
}

String? _dateValue(DateTime? value) {
  if (value == null) return null;
  final normalized = DateTime.utc(value.year, value.month, value.day);
  return normalized.toIso8601String().substring(0, 10);
}
