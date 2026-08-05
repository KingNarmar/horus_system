import '../../../../core/domain/value_objects/currency_code.dart';
import 'invoice_customer_snapshot.dart';
import 'invoice_status.dart';
import 'invoice_totals.dart';
import 'invoice_trip_line.dart';
import '../value_objects/invoice_date.dart';
import '../value_objects/invoice_number.dart';

final class Invoice {
  final String id;
  final String companyId;
  final InvoiceCustomerSnapshot customer;
  final InvoiceStatus status;
  final InvoiceNumber? number;
  final CurrencyCode currency;
  final List<InvoiceTripLine> lines;
  final InvoiceTotals totals;
  final InvoiceDate? issueDate;
  final InvoiceDate? dueDate;
  final String? notes;
  final String? cancellationReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  Invoice({
    required this.id,
    required this.companyId,
    required this.customer,
    required this.status,
    this.number,
    required this.currency,
    required List<InvoiceTripLine> lines,
    required this.totals,
    this.issueDate,
    this.dueDate,
    this.notes,
    this.cancellationReason,
    required this.createdAt,
    required this.updatedAt,
  }) : lines = List.unmodifiable(lines);
}
