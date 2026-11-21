import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:horus_system/core/data/services/timezone_business_time_zone_converter.dart';
import 'package:horus_system/core/domain/value_objects/business_date.dart';
import 'package:horus_system/features/reports/data/services/report_pdf_business_timestamp_formatter.dart';
import 'package:horus_system/features/reports/data/services/report_pdf_renderer_impl.dart';
import 'package:horus_system/features/reports/domain/entities/operational_trip_report.dart';
import 'package:horus_system/features/reports/domain/entities/report_date_range.dart';
import 'package:horus_system/features/reports/domain/entities/report_export_document.dart';
import 'package:horus_system/features/reports/domain/entities/report_export_kind.dart';
import 'package:horus_system/features/reports/domain/entities/report_export_labels.dart';
import 'package:horus_system/features/reports/domain/entities/report_export_table.dart';
import 'package:horus_system/features/reports/domain/entities/report_pdf_page_layout.dart';
import 'package:horus_system/features/reports/domain/entities/report_source_metadata.dart';

void main() {
  const timestamps = ReportPdfBusinessTimestampFormatter(
    TimezoneBusinessTimeZoneConverter(),
  );

  testWidgets('wide PDF paginates wrapped descriptions without losing row IDs', (
    tester,
  ) async {
    const rowCount = 48;
    final renderer = ReportPdfRendererImpl(
      timestampFormatter: timestamps,
      loadFonts: () async =>
          (regular: pw.Font.helvetica(), bold: pw.Font.helveticaBold()),
    );

    final result = await renderer.render(
      document: _document(),
      table: _wideTable(rowCount, rtl: false),
      labels: _labels(rtl: false),
      pageLayout: ReportPdfPageLayout.a4Landscape,
    );

    expect(result.failureOrNull, isNull);
    final bytes = result.dataOrNull!;
    expect(bytes.sublist(0, 4), [37, 80, 68, 70]);
    expect(_pageCount(bytes), greaterThan(1));

    // Each source row has one short stable ID, even when descriptive fields
    // wrap across lines or pages. No omitted or duplicated business rows.
    final ids = RegExp(r'\(TRIP-(\d+)\)')
        .allMatches(_decodedStreams(bytes))
        .map((match) => int.parse(match.group(1)!))
        .toList(growable: false);
    expect(ids, hasLength(rowCount));
    expect(ids.toSet(), Set<int>.from(List.generate(rowCount, (i) => i)));
    expect(_decodedStreams(bytes), contains('Customer'));
    expect(_decodedStreams(bytes), contains('Route'));
  });

  testWidgets('wide multi-page Arabic RTL PDF embeds Cairo for mixed content', (
    tester,
  ) async {
    // Use the production bundled Cairo fonts, rather than the Helvetica
    // test double. This also verifies offline Arabic font loading.
    final renderer = ReportPdfRendererImpl(timestampFormatter: timestamps);
    final result = await renderer.render(
      document: _document(companyName: 'شركة حورس للنقل الثقيل'),
      table: _wideTable(36, rtl: true),
      labels: _labels(rtl: true),
      pageLayout: ReportPdfPageLayout.a4Landscape,
    );

    expect(result.failureOrNull, isNull);
    final bytes = result.dataOrNull!;
    expect(bytes.sublist(0, 4), [37, 80, 68, 70]);
    expect(_pageCount(bytes), greaterThan(1));
    expect(latin1.decode(bytes), contains('/FontFile2'));
  });
}

ReportExportTable _wideTable(int count, {required bool rtl}) =>
    ReportExportTable(
      columns: const [
        ReportExportColumn.trip,
        ReportExportColumn.date,
        ReportExportColumn.customer,
        ReportExportColumn.driver,
        ReportExportColumn.tractorHead,
        ReportExportColumn.trailer,
        ReportExportColumn.route,
        ReportExportColumn.status,
      ],
      rows: List.generate(
        count,
        (index) => [
          ReportExportTextCell('TRIP-$index'),
          ReportExportDateCell(BusinessDate(year: 2026, month: 11, day: 21)),
          ReportExportTextCell(
            rtl
                ? 'عميل النقل الثقيل رقم $index مدينة دبي المنطقة الصناعية '
                      'قسم الاستلام وخدمات الشحن'
                : 'Customer $index industrial cargo handling and long distance '
                      'freight forwarding terminal',
          ),
          ReportExportTextCell(
            rtl
                ? 'السائق رقم $index شاحنات النقل البري'
                : 'Driver $index long-haul transport operations',
          ),
          ReportExportTextCell('DXB-$index'),
          ReportExportTextCell('TRL-$index'),
          ReportExportTextCell(
            rtl
                ? 'مسار $index من منطقة التحميل في دبي إلى محطة التفريغ '
                      'مع بيانات إضافية للموقع Route $index'
                : 'Route $index from industrial loading terminal to the '
                      'receiving warehouse via regional freight corridor',
          ),
          ReportExportTextCell(
            rtl ? 'جارٍ النقل $index' : 'In transit $index',
          ),
        ],
      ),
      totals: const [],
      currencyFractionDigits: 2,
    );

ReportExportDocument _document({String companyName = 'Tenant A'}) =>
    ReportExportDocument(
      companyId: 'company-a',
      companyName: companyName,
      logoBytes: null,
      kind: ReportExportKind.dailyTrips,
      dateRange: const ReportDateRange(),
      generatedAtUtc: DateTime.utc(2026, 11, 21),
      content: ReportExportOperationalContent(
        OperationalTripReport(
          metadata: OperationalReportSourceMetadata(
            companyId: 'company-a',
            businessTimezone: 'Asia/Dubai',
            businessDate: BusinessDate(year: 2026, month: 11, day: 21),
            sourceAsOfUtc: DateTime.utc(2026, 11, 21, 8),
            fromDate: null,
            toDate: null,
          ),
          dimension: OperationalReportDimension.day,
          groups: [],
        ),
      ),
    );

ReportExportLabels _labels({required bool rtl}) => ReportExportLabels(
  isRtl: rtl,
  localeName: rtl ? 'ar' : 'en',
  period: rtl ? 'الفترة' : 'Period',
  generatedAt: rtl ? 'تاريخ الإنشاء' : 'Generated',
  sourceAsOf: rtl ? 'قراءة المصدر' : 'Source read (server)',
  page: rtl ? 'صفحة' : 'Page',
  noRows: rtl ? 'لا توجد بيانات' : 'No rows',
  allDates: rtl ? 'جميع التواريخ' : 'All dates',
  unassigned: rtl ? 'غير محدد' : 'Unassigned',
  unavailable: rtl ? 'غير متاح' : 'N/A',
  titles: {
    ReportExportKind.dailyTrips: rtl ? 'الرحلات اليومية' : 'Daily trips',
  },
  columns: {
    ReportExportColumn.trip: rtl ? 'الرحلة' : 'Trip',
    ReportExportColumn.date: rtl ? 'التاريخ' : 'Date',
    ReportExportColumn.customer: rtl ? 'العميل' : 'Customer',
    ReportExportColumn.driver: rtl ? 'السائق' : 'Driver',
    ReportExportColumn.tractorHead: rtl ? 'رأس القاطرة' : 'Tractor head',
    ReportExportColumn.trailer: rtl ? 'المقطورة' : 'Trailer',
    ReportExportColumn.route: rtl ? 'المسار' : 'Route',
    ReportExportColumn.status: rtl ? 'الحالة' : 'Status',
  },
  tripStatuses: const {},
  invoiceStatuses: const {},
  fundingSources: const {},
);

int _pageCount(Uint8List bytes) =>
    RegExp(r'/Type\s*/Page\b').allMatches(latin1.decode(bytes)).length;

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
      // Font/image streams need not be zlib-encoded.
    }
  }
  return result.join('\n');
}
