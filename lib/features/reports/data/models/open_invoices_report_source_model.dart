import 'report_model_parsing.dart';
import 'report_source_metadata_model.dart';

final class OpenInvoicesReportSourceModel {
  final ReportSourceMetadataModel metadata;
  final int invoiceCurrencyMismatchCount;
  final int paymentCurrencyMismatchCount;
  final int invalidInvoiceAmountCount;
  final int invalidPaymentAmountCount;
  final int missingIssueDateCount;
  final List<OpenInvoiceModel> invoices;
  final List<OpenInvoicePaymentModel> payments;

  OpenInvoicesReportSourceModel({
    required this.metadata,
    required this.invoiceCurrencyMismatchCount,
    required this.paymentCurrencyMismatchCount,
    required this.invalidInvoiceAmountCount,
    required this.invalidPaymentAmountCount,
    required this.missingIssueDateCount,
    required List<OpenInvoiceModel> invoices,
    required List<OpenInvoicePaymentModel> payments,
  }) : invoices = List.unmodifiable(invoices),
       payments = List.unmodifiable(payments);

  factory OpenInvoicesReportSourceModel.fromMap(Map<String, dynamic> map) {
    final validation = requiredMap(map['validation'], 'validation');
    return OpenInvoicesReportSourceModel(
      metadata: ReportSourceMetadataModel.fromRoot(map),
      invoiceCurrencyMismatchCount: requiredInt(
        validation['invoice_currency_mismatch_count'],
        'invoice_currency_mismatch_count',
      ),
      paymentCurrencyMismatchCount: requiredInt(
        validation['payment_currency_mismatch_count'],
        'payment_currency_mismatch_count',
      ),
      invalidInvoiceAmountCount: requiredInt(
        validation['invalid_invoice_amount_count'],
        'invalid_invoice_amount_count',
      ),
      invalidPaymentAmountCount: requiredInt(
        validation['invalid_payment_amount_count'],
        'invalid_payment_amount_count',
      ),
      missingIssueDateCount: requiredInt(
        validation['missing_issue_date_count'],
        'missing_issue_date_count',
      ),
      invoices: requiredMapList(
        map['invoices'],
        'invoices',
      ).map(OpenInvoiceModel.fromMap).toList(growable: false),
      payments: requiredMapList(
        map['payments'],
        'payments',
      ).map(OpenInvoicePaymentModel.fromMap).toList(growable: false),
    );
  }
}

final class OpenInvoiceModel {
  final String invoiceId;
  final String? invoiceNumber;
  final String customerId;
  final String customerName;
  final String status;
  final String currencyCode;
  final int totalMinorUnits;
  final DateTime issueDate;
  final DateTime? dueDate;
  final DateTime? issuedAt;

  const OpenInvoiceModel({
    required this.invoiceId,
    required this.invoiceNumber,
    required this.customerId,
    required this.customerName,
    required this.status,
    required this.currencyCode,
    required this.totalMinorUnits,
    required this.issueDate,
    required this.dueDate,
    required this.issuedAt,
  });

  factory OpenInvoiceModel.fromMap(Map<String, dynamic> map) {
    return OpenInvoiceModel(
      invoiceId: requiredString(map['invoice_id'], 'invoice_id'),
      invoiceNumber: optionalString(map['invoice_number'], 'invoice_number'),
      customerId: requiredString(map['customer_id'], 'customer_id'),
      customerName: requiredString(map['customer_name'], 'customer_name'),
      status: requiredString(map['status'], 'status'),
      currencyCode: requiredString(map['currency_code'], 'currency_code'),
      totalMinorUnits: requiredInt(
        map['total_minor_units'],
        'total_minor_units',
      ),
      issueDate: requiredDate(map['issue_date'], 'issue_date'),
      dueDate: optionalDate(map['due_date'], 'due_date'),
      issuedAt: optionalDateTime(map['issued_at'], 'issued_at'),
    );
  }
}

final class OpenInvoicePaymentModel {
  final String paymentId;
  final String invoiceId;
  final String currencyCode;
  final int amountMinorUnits;
  final DateTime paymentDate;
  final DateTime createdAt;

  const OpenInvoicePaymentModel({
    required this.paymentId,
    required this.invoiceId,
    required this.currencyCode,
    required this.amountMinorUnits,
    required this.paymentDate,
    required this.createdAt,
  });

  factory OpenInvoicePaymentModel.fromMap(Map<String, dynamic> map) {
    return OpenInvoicePaymentModel(
      paymentId: requiredString(map['payment_id'], 'payment_id'),
      invoiceId: requiredString(map['invoice_id'], 'invoice_id'),
      currencyCode: requiredString(map['currency_code'], 'currency_code'),
      amountMinorUnits: requiredInt(
        map['amount_minor_units'],
        'amount_minor_units',
      ),
      paymentDate: requiredDate(map['payment_date'], 'payment_date'),
      createdAt: requiredDateTime(map['created_at'], 'created_at'),
    );
  }
}
