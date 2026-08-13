import '../../../../core/domain/value_objects/money.dart';
import '../../../invoices/domain/entities/invoice_status.dart';
import 'report_source_metadata.dart';

final class OpenInvoiceSourceInvoice {
  final String invoiceId;
  final String? invoiceNumber;
  final String customerId;
  final String customerName;
  final InvoiceStatus status;
  final Money total;
  final DateTime issueDate;
  final DateTime? dueDate;
  final DateTime? issuedAt;

  const OpenInvoiceSourceInvoice({
    required this.invoiceId,
    required this.invoiceNumber,
    required this.customerId,
    required this.customerName,
    required this.status,
    required this.total,
    required this.issueDate,
    required this.dueDate,
    required this.issuedAt,
  });
}

final class OpenInvoiceSourcePayment {
  final String paymentId;
  final String invoiceId;
  final Money amount;
  final DateTime paymentDate;
  final DateTime createdAt;

  const OpenInvoiceSourcePayment({
    required this.paymentId,
    required this.invoiceId,
    required this.amount,
    required this.paymentDate,
    required this.createdAt,
  });
}

final class OpenInvoicesReportSource {
  final ReportSourceMetadata metadata;
  final int invoiceCurrencyMismatchCount;
  final int paymentCurrencyMismatchCount;
  final int invalidInvoiceAmountCount;
  final int invalidPaymentAmountCount;
  final int missingIssueDateCount;
  final List<OpenInvoiceSourceInvoice> invoices;
  final List<OpenInvoiceSourcePayment> payments;

  OpenInvoicesReportSource({
    required this.metadata,
    required this.invoiceCurrencyMismatchCount,
    required this.paymentCurrencyMismatchCount,
    required this.invalidInvoiceAmountCount,
    required this.invalidPaymentAmountCount,
    required this.missingIssueDateCount,
    required List<OpenInvoiceSourceInvoice> invoices,
    required List<OpenInvoiceSourcePayment> payments,
  }) : invoices = List.unmodifiable(invoices),
       payments = List.unmodifiable(payments);
}

final class OpenInvoiceReportRow {
  final OpenInvoiceSourceInvoice invoice;
  final Money paid;
  final Money remaining;

  const OpenInvoiceReportRow({
    required this.invoice,
    required this.paid,
    required this.remaining,
  });
}

final class OpenInvoicesReport {
  final ReportSourceMetadata metadata;
  final List<OpenInvoiceReportRow> rows;
  final Money totalOutstanding;

  OpenInvoicesReport({
    required this.metadata,
    required List<OpenInvoiceReportRow> rows,
    required this.totalOutstanding,
  }) : rows = List.unmodifiable(rows);
}
