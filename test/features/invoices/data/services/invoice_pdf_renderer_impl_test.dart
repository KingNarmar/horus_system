import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:horus_system/core/domain/value_objects/currency_code.dart';
import 'package:horus_system/core/domain/value_objects/money.dart';
import 'package:horus_system/features/invoices/data/services/invoice_pdf_renderer_impl.dart';
import 'package:horus_system/features/invoices/data/services/invoice_pdf_route_cell.dart';
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
  test('uses a font-independent vector arrow for RTL invoice routes', () {
    final cell = InvoicePdfRouteCell.build(
      loadingLocation: 'Route1',
      unloadingLocation: 'Dubai',
      unavailable: 'N/A',
    );

    final direction = cell as pw.Directionality;
    final content = direction.child as pw.RichText;
    final spans = (content.text as pw.TextSpan).children!;
    expect(direction.textDirection, pw.TextDirection.ltr);
    expect(content.textDirection, pw.TextDirection.ltr);
    expect(content.softWrap, isTrue);
    expect((spans[0] as pw.TextSpan).text, 'Route1 ');
    expect((spans[1] as pw.WidgetSpan).child, isA<pw.CustomPaint>());
    expect((spans[2] as pw.TextSpan).text, ' Dubai');
    expect(
      spans.whereType<pw.TextSpan>().any(
        (span) => span.text?.contains('→') ?? false,
      ),
      isFalse,
    );
  });

  test(
    'keeps mixed Arabic/English locations in the correct business order',
    () {
      final cell = InvoicePdfRouteCell.build(
        loadingLocation: '  جبل علي  ',
        unloadingLocation: '  Dubai Route 1  ',
        unavailable: 'غير متاح',
      );

      final content = (cell as pw.Directionality).child as pw.RichText;
      final spans = (content.text as pw.TextSpan).children!;
      expect((spans.first as pw.TextSpan).text, 'جبل علي ');
      expect((spans.last as pw.TextSpan).text, ' Dubai Route 1');
      expect(spans[1], isA<pw.WidgetSpan>());
    },
  );

  test('shows localized fallback when both route ends are absent', () {
    final cell = InvoicePdfRouteCell.build(
      loadingLocation: ' ',
      unloadingLocation: null,
      unavailable: 'غير متاح',
    );
    final content = (cell as pw.Directionality).child as pw.Text;
    expect((content.text as pw.TextSpan).text, 'غير متاح');
  });

  test('one-sided route remains readable without an arrow', () {
    final cell = InvoicePdfRouteCell.build(
      loadingLocation: 'Jebel Ali',
      unloadingLocation: null,
      unavailable: 'N/A',
    );
    final content = (cell as pw.Directionality).child as pw.Text;
    expect((content.text as pw.TextSpan).text, 'Jebel Ali');
  });

  testWidgets('renders long route names on a multi-page invoice', (
    tester,
  ) async {
    final renderer = InvoicePdfRendererImpl(
      loadFonts: () async =>
          (regular: pw.Font.helvetica(), bold: pw.Font.helveticaBold()),
    );
    final result = await renderer.render(
      document: _document(
        lineCount: 90,
        loadingLocation: 'Jebel Ali Free Zone Industrial Area Gate Six',
        unloadingLocation: 'Dubai South Logistics District Cargo Terminal',
      ),
      labels: _labels,
    );

    expect(result.failureOrNull, isNull);
    expect(result.dataOrNull!.sublist(0, 4), [37, 80, 68, 70]);
  });

  testWidgets('generates a multipage invoice without network fonts', (
    tester,
  ) async {
    final renderer = InvoicePdfRendererImpl(
      loadFonts: () async =>
          (regular: pw.Font.helvetica(), bold: pw.Font.helveticaBold()),
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

  testWidgets('damaged private logo returns typed failure, not silent loss', (
    tester,
  ) async {
    final renderer = InvoicePdfRendererImpl(
      loadFonts: () async =>
          (regular: pw.Font.helvetica(), bold: pw.Font.helveticaBold()),
    );
    final result = await renderer.render(
      document: _document(
        lineCount: 1,
        logoBytes: Uint8List.fromList([1, 2, 3]),
      ),
      labels: _labels,
    );

    expect(
      result.failureOrNull?.code,
      InvoiceFailureCodes.pdfRenderUnavailable,
    );
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

InvoicePdfDocument _document({
  required int lineCount,
  Uint8List? logoBytes,
  String? loadingLocation,
  String? unloadingLocation,
}) {
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
        loadingLocation: loadingLocation,
        unloadingLocation: unloadingLocation,
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
    logoBytes: logoBytes ?? Uint8List(0),
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
