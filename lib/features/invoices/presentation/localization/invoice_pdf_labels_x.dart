import 'package:flutter/widgets.dart';

import '../../domain/entities/invoice_pdf_labels.dart';
import 'invoices_localizations.dart';

extension InvoicePdfLabelsX on BuildContext {
  InvoicePdfLabels get invoicePdfLabels {
    final strings = invoicesL10n;
    return InvoicePdfLabels(
      isRtl: Localizations.localeOf(this).languageCode == 'ar',
      title: strings.pdfTitle,
      statusDraft: strings.statusDraft,
      statusIssued: strings.statusIssued,
      statusPartiallyPaid: strings.statusPartiallyPaid,
      statusPaid: strings.statusPaid,
      statusCancelled: strings.statusCancelled,
      issuer: strings.pdfIssuer,
      customer: strings.customer,
      taxRegistration: strings.pdfTaxRegistration,
      invoiceNumber: strings.number,
      issueDate: strings.issueDate,
      dueDate: strings.dueDate,
      trip: strings.trip,
      serviceDate: strings.pdfServiceDate,
      route: strings.pdfRoute,
      quantity: strings.pdfQuantity,
      amount: strings.pdfAmount,
      subtotal: strings.subtotal,
      discount: strings.discount,
      taxableAmount: strings.taxableAmount,
      tax: strings.tax,
      total: strings.total,
      notes: strings.notes,
      page: strings.pdfPage,
      unavailable: strings.unavailableValue,
      legacyIdentityNotice: strings.pdfLegacyWarning,
    );
  }
}
