import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/features/reports/domain/entities/operational_trip_report.dart';
import 'package:horus_system/features/reports/domain/entities/report_source_metadata.dart';
import 'package:horus_system/features/reports/presentation/widgets/operational_report_view.dart';
import 'package:horus_system/features/trips/domain/entities/trip_status.dart';
import 'package:horus_system/l10n/app_localizations.dart';

void main() {
  testWidgets('uses mobile cards below data-table breakpoint', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _app(report: _report(), locale: const Locale('en')),
    );

    expect(find.byType(DataTable), findsNothing);
    expect(find.text('Unassigned'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('uses desktop data table at wide width', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _app(report: _report(), locale: const Locale('en')),
    );

    expect(find.byType(DataTable), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('daily trips hide internal trip id when trip number is missing', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _app(report: _dailyReportWithoutTripReference(), locale: const Locale('en')),
    );

    expect(find.text('Dubai → Abu Dhabi'), findsWidgets);
    expect(
      find.text('4ba8dc8f-fa8c-4099-ab7c-ffedef6d4d1b'),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Arabic daily trip card keeps the full route value LTR', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const route = 'Jebel Ali Port → Dubai South Logistics District';
    await tester.pumpWidget(
      _app(
        report: _dailyReportWithoutTripReference(
          loadingLocation: 'Jebel Ali Port',
          unloadingLocation: 'Dubai South Logistics District',
        ),
        locale: const Locale('ar'),
      ),
    );

    final routeFinder = find.text(route);
    expect(routeFinder, findsOneWidget);
    expect(
      Directionality.of(tester.element(routeFinder)),
      TextDirection.ltr,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('localizes unassigned group and status in Arabic RTL', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _app(report: _report(), locale: const Locale('ar')),
    );

    expect(find.text('غير مسند'), findsWidgets);
    final element = tester.element(find.text('غير مسند').first);
    expect(Directionality.of(element), TextDirection.rtl);
    expect(tester.takeException(), isNull);
  });
}

Widget _app({required OperationalTripReport report, required Locale locale}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: OperationalReportView(report: report)),
  );
}

OperationalTripReport _report() {
  final row = OperationalTripReportRow(
    tripId: 'trip-1',
    tripNumber: 'TR-1',
    operationalDate: DateTime(2026, 6, 20),
    status: TripStatus.cancelled,
    customerId: 'customer-1',
    customerName: 'Customer',
    driverId: null,
    driverName: null,
    tractorHeadId: null,
    tractorHeadPlateNumber: null,
    trailerId: null,
    trailerPlateNumber: null,
    routeId: 'route-1',
    loadingLocation: 'Dubai',
    unloadingLocation: 'Abu Dhabi',
    loadingOrderNumber: null,
    waybillNumber: null,
    cargoType: null,
    quantityTons: null,
  );
  return OperationalTripReport(
    metadata: OperationalReportSourceMetadata(
      companyId: 'company-1',
      businessTimezone: 'Asia/Dubai',
      businessDate: DateTime(2026, 8, 13),
      fromDate: null,
      toDate: null,
    ),
    dimension: OperationalReportDimension.driver,
    groups: [
      OperationalTripReportGroup(
        date: null,
        entityId: null,
        entityLabel: null,
        rows: [row],
      ),
    ],
  );
}

OperationalTripReport _dailyReportWithoutTripReference({
  String loadingLocation = 'Dubai',
  String unloadingLocation = 'Abu Dhabi',
}) {
  final row = OperationalTripReportRow(
    tripId: '4ba8dc8f-fa8c-4099-ab7c-ffedef6d4d1b',
    tripNumber: null,
    operationalDate: DateTime(2026, 9, 8),
    status: TripStatus.documentsReceived,
    customerId: 'customer-1',
    customerName: 'Customer',
    driverId: null,
    driverName: null,
    tractorHeadId: null,
    tractorHeadPlateNumber: null,
    trailerId: null,
    trailerPlateNumber: null,
    routeId: 'route-1',
    loadingLocation: loadingLocation,
    unloadingLocation: unloadingLocation,
    loadingOrderNumber: null,
    waybillNumber: null,
    cargoType: null,
    quantityTons: null,
  );
  return OperationalTripReport(
    metadata: OperationalReportSourceMetadata(
      companyId: 'company-1',
      businessTimezone: 'Asia/Dubai',
      businessDate: DateTime(2026, 9, 13),
      fromDate: null,
      toDate: null,
    ),
    dimension: OperationalReportDimension.day,
    groups: [
      OperationalTripReportGroup(
        date: DateTime(2026, 9, 8),
        entityId: null,
        entityLabel: null,
        rows: [row],
      ),
    ],
  );
}
