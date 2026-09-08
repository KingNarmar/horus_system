import '../../../../core/data/utils/db_date.dart';
import '../../../../core/domain/value_objects/business_date.dart';
import '../constants/invoices_rpc_constants.dart';

final class InvoiceDraftWriteModel {
  final String companyId;
  final String customerId;
  final List<String> tripIds;
  final int discountMinorUnits;
  final int taxRateBasisPoints;
  final BusinessDate? issueDate;
  final BusinessDate? dueDate;
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
      InvoicesRpcConstants.issueDate: DbDate.encodeNullable(issueDate),
      InvoicesRpcConstants.dueDate: DbDate.encodeNullable(dueDate),
      InvoicesRpcConstants.notes: notes,
    };
  }

  Map<String, dynamic> updateParams({required String invoiceId}) {
    return {InvoicesRpcConstants.invoiceId: invoiceId, ...createParams()};
  }
}
