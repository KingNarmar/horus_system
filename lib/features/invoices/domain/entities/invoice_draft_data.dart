import '../../../../core/domain/value_objects/currency_code.dart';
import 'invoice_customer_snapshot.dart';
import 'invoice_totals.dart';
import 'invoice_trip_line.dart';
import '../value_objects/invoice_date.dart';

final class InvoiceDraftData {
  final String companyId;
  final InvoiceCustomerSnapshot customer;
  final CurrencyCode currency;
  final List<InvoiceTripLine> lines;
  final InvoiceTotals totals;
  final InvoiceDate? issueDate;
  final InvoiceDate? dueDate;
  final String? notes;

  InvoiceDraftData({
    required this.companyId,
    required this.customer,
    required this.currency,
    required List<InvoiceTripLine> lines,
    required this.totals,
    this.issueDate,
    this.dueDate,
    this.notes,
  }) : lines = List.unmodifiable(lines);
}
