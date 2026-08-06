import '../../../../core/domain/value_objects/currency_code.dart';
import '../../domain/entities/invoice.dart';
import '../../domain/entities/invoice_status.dart';
import '../../domain/value_objects/invoice_date.dart';
import '../../domain/value_objects/invoice_number.dart';
import '../models/invoice_model.dart';
import 'invoice_customer_snapshot_mapper.dart';
import 'invoice_totals_mapper.dart';
import 'invoice_trip_line_mapper.dart';

extension InvoiceModelMapper on InvoiceModel {
  Invoice toEntity() {
    final currency = CurrencyCode.tryParse(currencyCode);
    if (currency == null) {
      throw FormatException(
        'Invalid persisted invoice currency: $currencyCode.',
      );
    }

    final parsedStatus = InvoiceStatus.tryFromValue(status);
    if (parsedStatus == null) {
      throw FormatException('Invalid persisted invoice status: $status.');
    }

    final parsedNumber = invoiceNumber == null
        ? null
        : InvoiceNumber.tryParse(invoiceNumber!);
    if (invoiceNumber != null && parsedNumber == null) {
      throw FormatException(
        'Invalid persisted invoice number: $invoiceNumber.',
      );
    }

    final customerEntity = customer.toEntity();
    if (customerEntity.companyId != companyId) {
      throw const FormatException(
        'Persisted invoice customer snapshot has a tenant mismatch.',
      );
    }

    final lineEntities = lines.map((line) => line.toEntity()).toList();
    if (lineEntities.any((line) => line.amount.currency != currency)) {
      throw const FormatException(
        'Persisted invoice line currency does not match the invoice.',
      );
    }

    final totalsEntity = totals.toEntity();
    final totalsCurrencies = [
      totalsEntity.subtotal.currency,
      totalsEntity.discount.currency,
      totalsEntity.taxableAmount.currency,
      totalsEntity.taxAmount.currency,
      totalsEntity.grandTotal.currency,
    ];
    if (totalsCurrencies.any((value) => value != currency)) {
      throw const FormatException(
        'Persisted invoice totals currency does not match the invoice.',
      );
    }

    return Invoice(
      id: id,
      companyId: companyId,
      customer: customerEntity,
      status: parsedStatus,
      number: parsedNumber,
      currency: currency,
      lines: lineEntities,
      totals: totalsEntity,
      issueDate: issueDate == null
          ? null
          : InvoiceDate.fromDateTime(issueDate!),
      dueDate: dueDate == null ? null : InvoiceDate.fromDateTime(dueDate!),
      notes: notes,
      cancellationReason: cancellationReason,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
