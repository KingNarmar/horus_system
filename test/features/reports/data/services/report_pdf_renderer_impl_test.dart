import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:horus_system/core/domain/value_objects/business_date.dart';
import 'package:horus_system/core/domain/value_objects/currency_code.dart';
import 'package:horus_system/core/domain/value_objects/money.dart';
import 'package:horus_system/features/reports/data/services/report_pdf_renderer_impl.dart';
import 'package:horus_system/features/reports/domain/entities/operational_trip_report.dart';
import 'package:horus_system/features/reports/domain/entities/report_date_range.dart';
import 'package:horus_system/features/reports/domain/entities/report_export_document.dart';
import 'package:horus_system/features/reports/domain/entities/report_export_kind.dart';
import 'package:horus_system/features/reports/domain/entities/report_export_labels.dart';
import 'package:horus_system/features/reports/domain/entities/report_export_table.dart';
import 'package:horus_system/features/reports/domain/entities/report_source_metadata.dart';
import 'package:horus_system/features/reports/domain/failures/reports_failure_codes.dart';

void main() {
  final renderer = ReportPdfRendererImpl(
    loadFonts: () async =>
        (regular: pw.Font.helvetica(), bold: pw.Font.helveticaBold()),
  );

  testWidgets('a hundred report rows span pages without dropping IDs', (
    tester,
  ) async {
    final currency = CurrencyCode.tryParse('AED')!;
    final amount = Money(minorUnits: 1234567, currency: currency);
    final table = ReportExportTable(
      columns: const [
        ReportExportColumn.trip,
        ReportExportColumn.date,
        ReportExportColumn.amount,
      ],
      rows: List.generate(
        100,
        (index) => [
          ReportExportTextCell('TRIP-$index'),
          ReportExportDateCell(BusinessDate(year: 2026, month: 11, day: 19)),
          ReportExportMoneyCell(amount),
        ],
      ),
      totals: [
        ReportExportTotal(
          label: ReportExportColumn.totalExpenses,
          value: ReportExportMoneyCell(amount),
        ),
      ],
      currencyFractionDigits: 2,
    );

    final result = await renderer.render(
      document: _document(),
      table: table,
      labels: _labels,
    );

    expect(result.failureOrNull, isNull);
    final bytes = result.dataOrNull!;
    expect(bytes.sublist(0, 4), [37, 80, 68, 70]);
    final serialized = latin1.decode(bytes);
    expect(
      RegExp(r'/Type\s*/Page\b').allMatches(serialized).length,
      greaterThan(1),
    );

    final streams = _decodedStreams(bytes);
    final ids = RegExp(r'\(TRIP-(\d+)\)')
        .allMatches(streams)
        .map((match) => int.parse(match.group(1)!))
        .toList(growable: false);
    expect(ids, hasLength(100));
    expect(ids.toSet(), Set<int>.from(List.generate(100, (i) => i)));
    expect(streams, contains('12,345.67'));
    // The PDF text engine emits separate positioned word segments.
    expect(streams, contains('[(Source)]'));
    expect(streams, contains('[(12:20)]'));
    expect(streams, contains('[(Asia/Dubai)]'));
  });

  testWidgets('large report keeps all rows beyond twenty pages', (
    tester,
  ) async {
    final currency = CurrencyCode.tryParse('AED')!;
    final amount = Money(minorUnits: 1234567, currency: currency);
    const rowCount = 1000;
    final table = ReportExportTable(
      columns: const [
        ReportExportColumn.trip,
        ReportExportColumn.date,
        ReportExportColumn.amount,
      ],
      rows: List.generate(
        rowCount,
        (index) => [
          ReportExportTextCell('TRIP-$index'),
          ReportExportDateCell(BusinessDate(year: 2026, month: 11, day: 19)),
          ReportExportMoneyCell(amount),
        ],
      ),
      totals: [
        ReportExportTotal(
          label: ReportExportColumn.totalExpenses,
          value: ReportExportMoneyCell(amount),
        ),
      ],
      currencyFractionDigits: 2,
    );

    final result = await renderer.render(
      document: _document(),
      table: table,
      labels: _labels,
    );

    expect(result.failureOrNull, isNull);
    final bytes = result.dataOrNull!;
    final serialized = latin1.decode(bytes);
    final pageCount = RegExp(r'/Type\s*/Page\b').allMatches(serialized).length;
    expect(pageCount, greaterThan(20));

    final streams = _decodedStreams(bytes);
    final ids = RegExp(r'\(TRIP-(\d+)\)')
        .allMatches(streams)
        .map((match) => int.parse(match.group(1)!))
        .toList(growable: false);
    expect(ids, hasLength(rowCount));
    expect(ids.toSet(), Set<int>.from(List.generate(rowCount, (i) => i)));
    expect(streams, contains('12,345.67'));
    // The PDF text engine emits separate positioned word segments.
    expect(streams, contains('[(Source)]'));
    expect(streams, contains('[(12:20)]'));
    expect(streams, contains('[(Asia/Dubai)]'));
  });

  testWidgets('unknown company timezone fails rather than showing UTC', (
    tester,
  ) async {
    final result = await renderer.render(
      document: _document(businessTimezone: 'Invalid/Timezone'),
      table: ReportExportTable(
        columns: const [ReportExportColumn.trip],
        rows: const [],
        totals: const [],
        currencyFractionDigits: 0,
      ),
      labels: _labels,
    );

    expect(
      result.failureOrNull?.code,
      ReportsFailureCodes.pdfRenderUnavailable,
    );
  });

  testWidgets('unreadable company logo fails with typed render error', (
    tester,
  ) async {
    final result = await renderer.render(
      document: _document(logo: Uint8List.fromList([1, 2, 3])),
      table: ReportExportTable(
        columns: const [ReportExportColumn.trip],
        rows: const [],
        totals: const [],
        currencyFractionDigits: 0,
      ),
      labels: _labels,
    );
    expect(
      result.failureOrNull?.code,
      ReportsFailureCodes.pdfRenderUnavailable,
    );
  });

  testWidgets('unavailable offline fonts produce a typed failure', (
    tester,
  ) async {
    final offline = ReportPdfRendererImpl(
      loadFonts: () async => throw StateError('font unavailable'),
    );
    final result = await offline.render(
      document: _document(),
      table: ReportExportTable(
        columns: const [ReportExportColumn.trip],
        rows: const [],
        totals: const [],
        currencyFractionDigits: 0,
      ),
      labels: _labels,
    );
    expect(
      result.failureOrNull?.code,
      ReportsFailureCodes.pdfRenderUnavailable,
    );
  });
}

ReportExportDocument _document({
  Uint8List? logo,
  String businessTimezone = 'Asia/Dubai',
}) => ReportExportDocument(
  companyId: 'company-a',
  companyName: 'Tenant A',
  logoBytes: logo,
  kind: ReportExportKind.dailyTrips,
  dateRange: const ReportDateRange(),
  generatedAtUtc: DateTime.utc(2026, 11, 19),
  content: ReportExportOperationalContent(
    OperationalTripReport(
      metadata: OperationalReportSourceMetadata(
        companyId: 'company-a',
        businessTimezone: businessTimezone,
        businessDate: BusinessDate(year: 2026, month: 11, day: 19),
        sourceAsOfUtc: DateTime.utc(2026, 11, 19, 8, 20),
        fromDate: null,
        toDate: null,
      ),
      dimension: OperationalReportDimension.day,
      groups: [],
    ),
  ),
);

final ReportExportLabels _labels = ReportExportLabels(
  isRtl: false,
  localeName: 'en',
  period: 'Period',
  generatedAt: 'Generated',
  sourceAsOf: 'Source read (server)',
  page: 'Page',
  noRows: 'No rows',
  allDates: 'All dates',
  unassigned: 'Unassigned',
  unavailable: 'N/A',
  titles: const {ReportExportKind.dailyTrips: 'Daily trips'},
  columns: const {
    ReportExportColumn.trip: 'Trip',
    ReportExportColumn.date: 'Date',
    ReportExportColumn.amount: 'Amount',
    ReportExportColumn.totalExpenses: 'Total expenses',
  },
  tripStatuses: const {},
  invoiceStatuses: const {},
  fundingSources: const {},
);

String _decodedStreams(Uint8List bytes) {
  final serialized = latin1.decode(bytes);
  final result = <String>[];
  for (final marker in RegExp(r'stream\r?\n').allMatches(serialized)) {
    final end = serialized.indexOf('endstream', marker.end);
    if (end < 0) continue;
    var offset = end;
    if (offset > marker.end && bytes[offset - 1] == 10) offset--;
    if (offset > marker.end && bytes[offset - 1] == 13) offset--;
    try {
      result.add(latin1.decode(zlib.decode(bytes.sublist(marker.end, offset))));
    } on Exception {
      // Font/image binary streams are not guaranteed to use zlib.
    }
  }
  return result.join('\n');
}
