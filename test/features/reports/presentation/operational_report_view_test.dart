import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/core/domain/value_objects/currency_code.dart';
import 'package:horus_system/features/reports/domain/entities/operational_trip_report.dart';
import 'package:horus_system/features/reports/domain/entities/report_source_metadata.dart';
import 'package:horus_system/features/reports/presentation/widgets/operational_report_view.dart';
import 'package:horus_system/features/trips/domain/entities/trip_status.dart';
import 'package:horus_system/l10n/app_localizations.dart';

void main() {
  testWidgets('uses mobile cards below data-table breakpoint', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_app(report: _report(), locale: const Locale('en')));

    expect(find.byType(DataTable), findsNothing);
    expect(find.text('Unassigned'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('uses desktop data table at wide width', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_app(report: _report(), locale: const Locale('en')));

    expect(find.byType(DataTable), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('localizes unassigned group and status in Arabic RTL', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_app(report: _report(), locale: const Locale('ar')));

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
    metadata: ReportSourceMetadata(
      companyId: 'company-1',
      currency: CurrencyCode.tryParse('AED')!,
      baseCurrencyFractionDigits: 2,
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
