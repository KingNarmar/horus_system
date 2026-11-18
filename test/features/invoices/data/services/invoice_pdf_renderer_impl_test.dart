import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:horus_system/core/domain/value_objects/currency_code.dart';
import 'package:horus_system/core/domain/value_objects/money.dart';
import 'package:horus_system/features/invoices/data/services/invoice_pdf_renderer_impl.dart';
import 'package:horus_system/features/invoices/domain/entities/invoice.dart';
import 'package:horus_system/features/invoices/domain/entities/invoice_customer_snapshot.dart';
import 'package:horus_system/features/invoices/domain/entities/invoice_pdf_document.dart';
import 'package:horus_system/features/invoices/domain/entities/invoice_pdf_labels.dart';
import 'package:horus_system/features/invoices/domain/entities/invoice_status.dart';
import 'package:horus_system/features/invoices/domain/entities/invoice_totals.dart';
import 'package:horus_system/features/invoices/domain/entities/invoice_trip_line.dart';
import 'package:horus_system/features/invoices/domain/failures/invoice_failure_codes.dart';
import 'package:horus_system/features/invoices/domain/value_objects/tax_rate.dart';

void main() {
  testWidgets('generates a multipage invoice without network fonts', (
    tester,
  ) async {
    final renderer = InvoicePdfRendererImpl(
      loadFonts: () async => (
        regular: pw.Font.helvetica(),
        bold: pw.Font.helveticaBold(),
      ),
    );
    final result = await renderer.render(
      document: _document(lineCount: 90),
      labels: _labels,
    );

    expect(result.failureOrNull, isNull);
    final bytes = result.dataOrNull!;
    expect(bytes.length, greaterThan(100));
    expect(bytes.sublist(0, 4), [37, 80, 68, 70]);
  });

  testWidgets('unavailable font reports typed rendering failure', (
    tester,
  ) async {
    final renderer = InvoicePdfRendererImpl(
      loadFonts: () async => throw StateError('offline'),
    );
    final result = await renderer.render(
      document: _document(lineCount: 1),
      labels: _labels,
    );

    expect(
      result.failureOrNull?.code,
      InvoiceFailureCodes.pdfRenderUnavailable,
    );
  });
}

InvoicePdfDocument _document({required int lineCount}) {
  final currency = CurrencyCode.tryParse('AED')!;
  final amount = Money(minorUnits: 10000, currency: currency);
  final zero = Money(minorUnits: 0, currency: currency);
  final invoice = Invoice(
    id: 'invoice-1',
    companyId: 'company-1',
    customer: const InvoiceCustomerSnapshot(
      companyId: 'company-1',
      customerId: 'customer-1',
      name: 'Customer',
    ),
    status: InvoiceStatus.issued,
    currency: currency,
    lines: List.generate(
      lineCount,
      (index) => InvoiceTripLine(
        tripId: 'trip-$index',
        tripNumber: 'TRIP-$index',
        amount: amount,
      ),
    ),
    totals: InvoiceTotals(
      subtotal: amount,
      discount: zero,
      taxableAmount: amount,
      taxRate: TaxRate.tryCreate(0)!,
      taxAmount: zero,
      grandTotal: amount,
    ),
    createdAt: DateTime.utc(2026, 11, 18),
    updatedAt: DateTime.utc(2026, 11, 18),
  );
  return InvoicePdfDocument(
    invoice: invoice,
    issuer: const InvoicePdfIssuerIdentity(name: 'Issuer'),
    logoBytes: Uint8List(0),
    currencyFractionDigits: 2,
  );
}

const InvoicePdfLabels _labels = InvoicePdfLabels(
  isRtl: false,
  title: 'Invoice',
  statusDraft: 'Draft',
  statusIssued: 'Issued',
  statusPartiallyPaid: 'Partially paid',
  statusPaid: 'Paid',
  statusCancelled: 'Cancelled',
  issuer: 'Issuer',
  customer: 'Customer',
  taxRegistration: 'Tax number',
  invoiceNumber: 'Invoice number',
  issueDate: 'Issue date',
  dueDate: 'Due date',
  trip: 'Trip',
  serviceDate: 'Service date',
  route: 'Route',
  quantity: 'Quantity',
  amount: 'Amount',
  subtotal: 'Subtotal',
  discount: 'Discount',
  taxableAmount: 'Taxable',
  tax: 'Tax',
  total: 'Total',
  notes: 'Notes',
  page: 'Page',
  unavailable: 'N/A',
  legacyIdentityNotice: 'Identity unverified',
);
