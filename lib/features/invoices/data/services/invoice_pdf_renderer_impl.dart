import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../../core/domain/value_objects/business_date.dart';
import '../../../../core/domain/value_objects/money.dart';
import '../../../../core/errors/common_failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/invoice_pdf_document.dart';
import '../../domain/entities/invoice_pdf_labels.dart';
import '../../domain/entities/invoice_status.dart';
import '../../domain/entities/invoice_issuer_snapshot.dart';
import '../../domain/failures/invoice_failure_codes.dart';
import '../../domain/services/invoice_pdf_renderer.dart';
import '../constants/invoice_pdf_style.dart';
import 'invoice_pdf_route_cell.dart';

typedef InvoicePdfFontLoader =
    Future<({pw.Font regular, pw.Font bold})> Function();

/// A4 multipage document generation. All numbers and line values are
/// presented from the authorized immutable invoice aggregate.
final class InvoicePdfRendererImpl implements InvoicePdfRenderer {
  final InvoicePdfFontLoader _loadFonts;

  InvoicePdfRendererImpl({InvoicePdfFontLoader? loadFonts})
    : _loadFonts = loadFonts ?? _loadGoogleFonts;

  @override
  Future<Result<Uint8List>> render({
    required InvoicePdfDocument document,
    required InvoicePdfLabels labels,
  }) async {
    try {
      final fonts = await _loadFonts();
      final logo = await _decodeLogo(document.logoBytes);
      final invoice = document.invoice;
      final rightToLeft = labels.isRtl;
      final pdf = pw.Document();
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(InvoicePdfStyle.pageMargin),
          textDirection: rightToLeft
              ? pw.TextDirection.rtl
              : pw.TextDirection.ltr,
          theme: pw.ThemeData.withFont(base: fonts.regular, bold: fonts.bold),
          build: (context) => [
            _issuerHeader(document, labels, logo, fonts.bold),
            pw.SizedBox(height: InvoicePdfStyle.sectionGap),
            _heading(invoice.status, labels, fonts.bold),
            pw.SizedBox(height: InvoicePdfStyle.sectionGap),
            _invoiceInfo(document, labels),
            pw.SizedBox(height: InvoicePdfStyle.sectionGap),
            _lines(document, labels, fonts.bold),
            pw.SizedBox(height: InvoicePdfStyle.sectionGap),
            _totals(document, labels, fonts.bold),
            if (invoice.notes != null) ...[
              pw.SizedBox(height: InvoicePdfStyle.sectionGap),
              pw.Text('${labels.notes}: ${invoice.notes}'),
            ],
            if (document.issuer.snapshotSource ==
                InvoiceIssuerSnapshotSource.legacyBaseline) ...[
              pw.SizedBox(height: InvoicePdfStyle.sectionGap),
              pw.Text(
                labels.legacyIdentityNotice,
                style: const pw.TextStyle(fontSize: InvoicePdfStyle.smallSize),
              ),
            ],
          ],
          footer: (context) => pw.Align(
            alignment: pw.Alignment.center,
            child: pw.Text(
              '${labels.page} ${context.pageNumber} / ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: InvoicePdfStyle.smallSize),
            ),
          ),
        ),
      );
      return Success(await pdf.save());
    } catch (_) {
      return const FailureResult(
        ServerFailure(code: InvoiceFailureCodes.pdfRenderUnavailable),
      );
    }
  }

  static Future<({pw.Font regular, pw.Font bold})> _loadGoogleFonts() async {
    final regular = await PdfGoogleFonts.cairoRegular();
    final bold = await PdfGoogleFonts.cairoBold();
    return (regular: regular, bold: bold);
  }

  static Future<pw.MemoryImage?> _decodeLogo(Uint8List? bytes) async {
    if (bytes == null || bytes.isEmpty) return null;
    final codec = await ui.instantiateImageCodec(bytes);
    try {
      final frame = await codec.getNextFrame();
      try {
        final data = await frame.image.toByteData(
          format: ui.ImageByteFormat.png,
        );
        if (data == null) {
          throw const FormatException('Unrenderable invoice issuer logo.');
        }
        return pw.MemoryImage(data.buffer.asUint8List());
      } finally {
        frame.image.dispose();
      }
    } finally {
      codec.dispose();
    }
  }

  static pw.Widget _issuerHeader(
    InvoicePdfDocument document,
    InvoicePdfLabels labels,
    pw.MemoryImage? logo,
    pw.Font bold,
  ) {
    final issuer = document.issuer;
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (logo != null) ...[
          pw.Image(
            logo,
            width: InvoicePdfStyle.logoSize,
            height: InvoicePdfStyle.logoSize,
          ),
          pw.SizedBox(width: InvoicePdfStyle.sectionGap),
        ],
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(labels.issuer),
              pw.Text(
                issuer.name,
                style: pw.TextStyle(
                  font: bold,
                  fontSize: InvoicePdfStyle.issuerSize,
                ),
              ),
              ..._addressLines([
                issuer.businessType,
                issuer.address,
                issuer.city,
                issuer.country,
                issuer.phone,
                issuer.email,
              ]),
              if (issuer.taxRegistrationNumber != null)
                pw.Text(
                  '${labels.taxRegistration}: '
                  '${issuer.taxRegistrationNumber}',
                ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _heading(
    InvoiceStatus status,
    InvoicePdfLabels labels,
    pw.Font bold,
  ) {
    final statusLabel = switch (status) {
      InvoiceStatus.draft => labels.statusDraft,
      InvoiceStatus.issued => labels.statusIssued,
      InvoiceStatus.partiallyPaid => labels.statusPartiallyPaid,
      InvoiceStatus.paid => labels.statusPaid,
      InvoiceStatus.cancelled => labels.statusCancelled,
    };
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          labels.title,
          style: pw.TextStyle(
            font: bold,
            fontSize: InvoicePdfStyle.headingSize,
          ),
        ),
        pw.SizedBox(height: InvoicePdfStyle.itemGap),
        pw.Container(
          padding: const pw.EdgeInsets.all(InvoicePdfStyle.statusPadding),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: InvoicePdfStyle.statusBorder),
          ),
          child: pw.Text(statusLabel, style: pw.TextStyle(font: bold)),
        ),
      ],
    );
  }

  static pw.Widget _invoiceInfo(
    InvoicePdfDocument document,
    InvoicePdfLabels labels,
  ) {
    final invoice = document.invoice;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _field(
          labels.invoiceNumber,
          invoice.number?.value ??
              (invoice.status == InvoiceStatus.draft
                  ? labels.statusDraft
                  : labels.unavailable),
        ),
        _field(labels.issueDate, _date(invoice.issueDate?.value, labels)),
        _field(labels.dueDate, _date(invoice.dueDate?.value, labels)),
        pw.SizedBox(height: InvoicePdfStyle.itemGap),
        pw.Text(
          labels.customer,
          style: const pw.TextStyle(
            fontSize: InvoicePdfStyle.customerHeadingSize,
          ),
        ),
        pw.Text(invoice.customer.name),
        ..._addressLines([
          invoice.customer.address,
          invoice.customer.city,
          invoice.customer.country,
        ]),
        if (invoice.customer.taxRegistrationNumber != null)
          _field(
            labels.taxRegistration,
            invoice.customer.taxRegistrationNumber!,
          ),
      ],
    );
  }

  static pw.Widget _lines(
    InvoicePdfDocument document,
    InvoicePdfLabels labels,
    pw.Font bold,
  ) {
    final rows = document.invoice.lines
        .map((line) {
          return <dynamic>[
            line.tripNumber ??
                line.loadingOrderNumber ??
                line.waybillNumber ??
                labels.unavailable,
            _date(line.serviceDate, labels),
            InvoicePdfRouteCell.build(
              loadingLocation: line.loadingLocation,
              unloadingLocation: line.unloadingLocation,
              unavailable: labels.unavailable,
            ),
            line.quantityTons?.toString() ?? labels.unavailable,
            _money(line.amount, document.currencyFractionDigits),
          ];
        })
        .toList(growable: false);
    return pw.TableHelper.fromTextArray(
      headers: [
        labels.trip,
        labels.serviceDate,
        labels.route,
        labels.quantity,
        labels.amount,
      ],
      data: rows,
      headerStyle: pw.TextStyle(font: bold, fontSize: InvoicePdfStyle.bodySize),
      cellStyle: const pw.TextStyle(fontSize: InvoicePdfStyle.bodySize),
      cellPadding: const pw.EdgeInsets.all(InvoicePdfStyle.tablePadding),
      columnWidths: const {
        0: pw.FlexColumnWidth(InvoicePdfStyle.tripColumnFlex),
        1: pw.FlexColumnWidth(InvoicePdfStyle.dateColumnFlex),
        2: pw.FlexColumnWidth(InvoicePdfStyle.routeColumnFlex),
        3: pw.FlexColumnWidth(InvoicePdfStyle.quantityColumnFlex),
        4: pw.FlexColumnWidth(InvoicePdfStyle.amountColumnFlex),
      },
      headerDecoration: const pw.BoxDecoration(
        color: InvoicePdfStyle.tableHeader,
      ),
    );
  }

  static pw.Widget _totals(
    InvoicePdfDocument document,
    InvoicePdfLabels labels,
    pw.Font bold,
  ) {
    final totals = document.invoice.totals;
    final digits = document.currencyFractionDigits;
    return pw.Inseparable(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          _field(labels.subtotal, _money(totals.subtotal, digits)),
          _field(labels.discount, _money(totals.discount, digits)),
          _field(labels.taxableAmount, _money(totals.taxableAmount, digits)),
          _field(labels.tax, _money(totals.taxAmount, digits)),
          pw.SizedBox(height: InvoicePdfStyle.itemGap),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(labels.total, style: pw.TextStyle(font: bold)),
              pw.Text(
                _money(totals.grandTotal, digits),
                style: pw.TextStyle(font: bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _field(String label, String value) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [pw.Text(label), pw.Text(value)],
    );
  }

  static List<pw.Widget> _addressLines(List<String?> values) {
    return values
        .whereType<String>()
        .where((value) => value.trim().isNotEmpty)
        .map((value) => pw.Text(value))
        .toList(growable: false);
  }

  static String _date(BusinessDate? date, InvoicePdfLabels labels) {
    if (date == null) return labels.unavailable;
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  /// Decimal presentation only, never business arithmetic or total changes.
  static String _money(Money money, int fractionDigits) {
    final scale = List<int>.generate(
      fractionDigits,
      (index) => index,
    ).fold<int>(1, (value, _) => value * 10);
    final magnitude = money.minorUnits.abs();
    final whole = magnitude ~/ scale;
    final fractional = magnitude % scale;
    final sign = money.minorUnits < 0 ? '-' : '';
    final decimals = fractionDigits == 0
        ? ''
        : '.${fractional.toString().padLeft(fractionDigits, '0')}';
    return '$sign$whole$decimals ${money.currency.value}';
  }
}
