import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../../core/domain/value_objects/business_date.dart';
import '../../../../core/domain/value_objects/money.dart';
import '../../../../core/errors/common_failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/report_export_document.dart';
import '../../domain/entities/report_export_labels.dart';
import '../../domain/entities/report_export_table.dart';
import '../../domain/failures/reports_failure_codes.dart';
import '../../domain/services/report_pdf_renderer.dart';
import '../constants/report_pdf_style.dart';

typedef ReportPdfFontLoader =
    Future<({pw.Font regular, pw.Font bold})> Function();

/// Local serialization of a pre-authorized typed Domain snapshot.
final class ReportPdfRendererImpl implements ReportPdfRenderer {
  final ReportPdfFontLoader _loadFonts;

  ReportPdfRendererImpl({ReportPdfFontLoader? loadFonts})
    : _loadFonts = loadFonts ?? _defaultFonts;

  @override
  Future<Result<Uint8List>> render({
    required ReportExportDocument document,
    required ReportExportTable table,
    required ReportExportLabels labels,
  }) async {
    try {
      // Date formatting must also work outside a Flutter app bootstrap.
      await initializeDateFormatting(labels.localeName);
      final fonts = await _loadFonts();
      final image = await _logo(document.logoBytes);
      final pdf = pw.Document();
      final headings = [
        for (final column in table.columns) labels.columns[column]!,
      ];
      final rows = [
        for (final row in table.rows)
          [
            for (final cell in row)
              _display(cell, labels, table.currencyFractionDigits),
          ],
      ];

      pdf.addPage(
        pw.MultiPage(
          pageFormat: table.columns.length > 5
              ? PdfPageFormat.a4.landscape
              : PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(ReportPdfStyle.margin),
          textDirection: labels.isRtl
              ? pw.TextDirection.rtl
              : pw.TextDirection.ltr,
          theme: pw.ThemeData.withFont(base: fonts.regular, bold: fonts.bold),
          header: (context) => _header(document, image, fonts.bold),
          footer: (context) => pw.Align(
            alignment: pw.Alignment.center,
            child: pw.Text(
              '${labels.page} ${context.pageNumber} / ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: ReportPdfStyle.smallSize),
            ),
          ),
          build: (context) => [
            pw.Text(
              labels.titles[document.kind]!,
              style: pw.TextStyle(
                font: fonts.bold,
                fontSize: ReportPdfStyle.headingSize,
              ),
            ),
            pw.SizedBox(height: ReportPdfStyle.sectionGap),
            pw.Text(
              '${labels.period}: ${_dateRange(document, labels)}',
              style: const pw.TextStyle(fontSize: ReportPdfStyle.textSize),
            ),
            pw.Text(
              '${labels.generatedAt}: ${document.generatedAtUtc.toIso8601String()}',
              style: const pw.TextStyle(fontSize: ReportPdfStyle.smallSize),
            ),
            pw.SizedBox(height: ReportPdfStyle.sectionGap),
            if (rows.isEmpty)
              pw.Text(labels.noRows)
            else
              pw.TableHelper.fromTextArray(
                headers: headings,
                data: rows,
                headerCount: 1,
                headerStyle: pw.TextStyle(
                  font: fonts.bold,
                  fontSize: ReportPdfStyle.tableTextSize,
                ),
                cellStyle: const pw.TextStyle(
                  fontSize: ReportPdfStyle.tableTextSize,
                ),
                cellPadding: const pw.EdgeInsets.all(
                  ReportPdfStyle.tablePadding,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: ReportPdfStyle.tableHeader,
                ),
                border: pw.TableBorder.all(
                  color: ReportPdfStyle.tableBorder,
                  width: 0.4,
                ),
                cellAlignment: pw.Alignment.centerLeft,
              ),
            if (table.totals.isNotEmpty) ...[
              pw.SizedBox(height: ReportPdfStyle.sectionGap),
              ...table.totals.map(
                (total) => pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(
                    vertical: ReportPdfStyle.tablePadding,
                  ),
                  child: pw.Text(
                    '${labels.columns[total.label]}: '
                    '${_display(total.value, labels, table.currencyFractionDigits)}',
                    style: pw.TextStyle(
                      font: fonts.bold,
                      fontSize: ReportPdfStyle.textSize,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
      return Success(await pdf.save());
    } catch (_) {
      return const FailureResult(
        ServerFailure(code: ReportsFailureCodes.pdfRenderUnavailable),
      );
    }
  }

  static Future<({pw.Font regular, pw.Font bold})> _defaultFonts() async {
    final regular = await PdfGoogleFonts.cairoRegular();
    final bold = await PdfGoogleFonts.cairoBold();
    return (regular: regular, bold: bold);
  }

  static Future<pw.MemoryImage?> _logo(Uint8List? bytes) async {
    if (bytes == null || bytes.isEmpty) return null;
    final codec = await ui.instantiateImageCodec(bytes);
    try {
      final frame = await codec.getNextFrame();
      try {
        final data = await frame.image.toByteData(
          format: ui.ImageByteFormat.png,
        );
        if (data == null) throw const FormatException('Invalid image.');
        return pw.MemoryImage(data.buffer.asUint8List());
      } finally {
        frame.image.dispose();
      }
    } finally {
      codec.dispose();
    }
  }

  static pw.Widget _header(
    ReportExportDocument document,
    pw.MemoryImage? image,
    pw.Font bold,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: ReportPdfStyle.sectionGap),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          if (image != null) ...[
            pw.Image(
              image,
              width: ReportPdfStyle.logoSize,
              height: ReportPdfStyle.logoSize,
            ),
            pw.SizedBox(width: ReportPdfStyle.sectionGap),
          ],
          pw.Expanded(
            child: pw.Text(
              document.companyName,
              style: pw.TextStyle(
                font: bold,
                fontSize: ReportPdfStyle.headingSize,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _dateRange(
    ReportExportDocument document,
    ReportExportLabels labels,
  ) {
    final from = document.dateRange.fromDate;
    final to = document.dateRange.toDate;
    return '${from == null ? labels.allDates : _date(from, labels.localeName)}'
        ' - '
        '${to == null ? labels.allDates : _date(to, labels.localeName)}';
  }

  static String _date(BusinessDate date, String localeName) => DateFormat.yMd(
    localeName,
  ).format(DateTime(date.year, date.month, date.day));

  static String _display(
    ReportExportCell cell,
    ReportExportLabels labels,
    int fractionDigits,
  ) => switch (cell) {
    ReportExportTextCell(:final value) =>
      value.trim().isEmpty ? labels.unassigned : value,
    ReportExportDateCell(:final value) => _date(value, labels.localeName),
    ReportExportOptionalDateCell(:final value) =>
      value == null ? labels.unavailable : _date(value, labels.localeName),
    ReportExportCountCell(:final value) => NumberFormat.decimalPattern(
      labels.localeName,
    ).format(value),
    ReportExportMoneyCell(:final value) => _money(
      value,
      fractionDigits,
      labels.localeName,
    ),
    ReportExportTripStatusCell(:final value) => labels.tripStatuses[value]!,
    ReportExportInvoiceStatusCell(:final value) =>
      labels.invoiceStatuses[value]!,
    ReportExportFundingCell(:final value) => labels.fundingSources[value]!,
  };

  /// Avoid converting Money.minorUnits to double before formatting.
  static String _money(Money money, int fractionDigits, String localeName) {
    var factor = 1;
    for (var i = 0; i < fractionDigits; i++) {
      factor *= 10;
    }
    final minor = BigInt.from(money.minorUnits);
    final absolute = minor.abs();
    final divisor = BigInt.from(factor);
    final whole = (absolute ~/ divisor).toInt();
    final fractional = (absolute % divisor).toString().padLeft(
      fractionDigits,
      '0',
    );
    final formatter = NumberFormat.decimalPattern(localeName);
    final sign = minor.isNegative ? '-' : '';
    final decimal = fractionDigits == 0
        ? ''
        : '${formatter.symbols.DECIMAL_SEP}$fractional';
    return '${money.currency.value} $sign${formatter.format(whole)}$decimal';
  }
}
