import '../../../../core/data/constants/db_common_fields.dart';
import '../constants/invoices_db_fields.dart';
import '../utils/invoice_data_parser.dart';
import 'invoice_customer_snapshot_model.dart';
import 'invoice_totals_model.dart';
import 'invoice_trip_line_model.dart';

final class InvoiceModel {
  final String id;
  final String companyId;
  final InvoiceCustomerSnapshotModel customer;
  final String status;
  final String? invoiceNumber;
  final String currencyCode;
  final List<InvoiceTripLineModel> lines;
  final InvoiceTotalsModel totals;
  final DateTime? issueDate;
  final DateTime? dueDate;
  final String? notes;
  final String? cancellationReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  InvoiceModel({
    required this.id,
    required this.companyId,
    required this.customer,
    required this.status,
    this.invoiceNumber,
    required this.currencyCode,
    required List<InvoiceTripLineModel> lines,
    required this.totals,
    this.issueDate,
    this.dueDate,
    this.notes,
    this.cancellationReason,
    required this.createdAt,
    required this.updatedAt,
  }) : lines = List.unmodifiable(lines);

  factory InvoiceModel.fromMap(Map<String, dynamic> map) {
    final lineMaps = InvoiceDataParser.mapList(
      map[InvoicesDbFields.linesRelation],
      InvoicesDbFields.linesRelation,
    );
    final lineModels =
        lineMaps.map(InvoiceTripLineModel.fromMap).toList(growable: false)
          ..sort(
            (left, right) => left.linePosition.compareTo(right.linePosition),
          );

    return InvoiceModel(
      id: InvoiceDataParser.requiredString(
        map[DbCommonFields.id],
        DbCommonFields.id,
      ),
      companyId: InvoiceDataParser.requiredString(
        map[DbCommonFields.companyId],
        DbCommonFields.companyId,
      ),
      customer: InvoiceCustomerSnapshotModel.fromInvoiceMap(map),
      status: InvoiceDataParser.requiredString(
        map[InvoicesDbFields.status],
        InvoicesDbFields.status,
      ),
      invoiceNumber: InvoiceDataParser.optionalString(
        map[InvoicesDbFields.invoiceNumber],
      ),
      currencyCode: InvoiceDataParser.requiredString(
        map[InvoicesDbFields.currencyCode],
        InvoicesDbFields.currencyCode,
      ),
      lines: lineModels,
      totals: InvoiceTotalsModel.fromMap(map),
      issueDate: InvoiceDataParser.optionalDate(
        map[InvoicesDbFields.issueDate],
        InvoicesDbFields.issueDate,
      ),
      dueDate: InvoiceDataParser.optionalDate(
        map[InvoicesDbFields.dueDate],
        InvoicesDbFields.dueDate,
      ),
      notes: InvoiceDataParser.optionalString(map[InvoicesDbFields.notes]),
      cancellationReason: InvoiceDataParser.optionalString(
        map[InvoicesDbFields.cancellationReason],
      ),
      createdAt: InvoiceDataParser.requiredDateTime(
        map[DbCommonFields.createdAt],
        DbCommonFields.createdAt,
      ),
      updatedAt: InvoiceDataParser.requiredDateTime(
        map[DbCommonFields.updatedAt],
        DbCommonFields.updatedAt,
      ),
    );
  }
}
