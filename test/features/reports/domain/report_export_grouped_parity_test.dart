import 'package:test/test.dart';

import 'package:horus_system/core/domain/value_objects/business_date.dart';
import 'package:horus_system/features/reports/domain/entities/operational_trip_report.dart';
import 'package:horus_system/features/reports/domain/entities/report_date_range.dart';
import 'package:horus_system/features/reports/domain/entities/report_export_document.dart';
import 'package:horus_system/features/reports/domain/entities/report_export_kind.dart';
import 'package:horus_system/features/reports/domain/entities/report_export_table.dart';
import 'package:horus_system/features/reports/domain/entities/report_source_metadata.dart';
import 'package:horus_system/features/reports/domain/services/operational_report_aggregator.dart';
import 'package:horus_system/features/reports/domain/services/report_export_projector.dart';
import 'package:horus_system/features/trips/domain/entities/trip_status.dart';

void main() {
  final date = BusinessDate(year: 2026, month: 11, day: 21);
  final metadata = OperationalReportSourceMetadata(
    companyId: 'company-a',
    businessTimezone: 'Asia/Dubai',
    businessDate: date,
    fromDate: null,
    toDate: null,
  );
  const aggregator = OperationalReportAggregator();
  const projector = ReportExportProjector();

  OperationalTripReportRow row({
    required String id,
    String? driverId,
    String? driverName,
    String? tractorId,
    String? tractorPlate,
    String? trailerId,
    String? trailerPlate,
  }) => OperationalTripReportRow(
    tripId: id,
    tripNumber: id,
    operationalDate: date,
    status: TripStatus.created,
    customerId: 'customer-a',
    customerName: 'Customer A',
    driverId: driverId,
    driverName: driverName,
    tractorHeadId: tractorId,
    tractorHeadPlateNumber: tractorPlate,
    trailerId: trailerId,
    trailerPlateNumber: trailerPlate,
    routeId: 'route-a',
    loadingLocation: 'Dubai',
    unloadingLocation: 'Port',
    loadingOrderNumber: null,
    waybillNumber: null,
    cargoType: null,
    quantityTons: null,
  );

  final trips = [
    row(
      id: 'trip-1',
      driverId: 'driver-a',
      driverName: 'Driver A',
      tractorId: 'tractor-a',
      tractorPlate: 'TR-1',
      trailerId: 'trailer-a',
      trailerPlate: 'TL-1',
    ),
    row(id: 'trip-2'),
    row(
      id: 'trip-3',
      driverId: 'driver-a',
      driverName: 'Driver A',
      tractorId: 'tractor-a',
      tractorPlate: 'TR-1',
      trailerId: 'trailer-a',
      trailerPlate: 'TL-1',
    ),
  ];

  for (final kind in [
    ReportExportKind.tripsByCustomer,
    ReportExportKind.tripsByRoute,
    ReportExportKind.tripsByDriver,
    ReportExportKind.tripsByTractorHead,
    ReportExportKind.tripsByTrailer,
  ]) {
    test('${kind.name} exports identical Domain group labels and counts', () {
      final dimension = kind.operationalDimension!;
      final groups = aggregator.group(rows: trips, dimension: dimension);
      final report = OperationalTripReport(
        metadata: metadata,
        dimension: dimension,
        groups: groups,
      );
      final exported = projector.project(
        ReportExportDocument(
          companyId: 'company-a',
          companyName: 'Tenant A',
          logoBytes: null,
          kind: kind,
          dateRange: const ReportDateRange(),
          generatedAtUtc: DateTime.utc(2026, 11, 21),
          content: ReportExportOperationalContent(report),
        ),
      );

      expect(exported.columns, hasLength(2));
      expect(exported.rows.length, groups.length);
      expect(report.totalTrips, trips.length);
      final exportCounts = <int>[];
      for (var index = 0; index < groups.length; index++) {
        final group = groups[index];
        final output = exported.rows[index];
        expect(output, hasLength(2));
        final groupLabel = output[0] as ReportExportTextCell;
        final count = output[1] as ReportExportCountCell;
        expect(count.value, group.tripCount);
        exportCounts.add(count.value);

        if (dimension != OperationalReportDimension.route) {
          expect(groupLabel.value, group.entityLabel ?? '');
        } else {
          expect(groupLabel.value, 'Dubai - Port');
        }
      }
      expect(exportCounts.reduce((a, b) => a + b), trips.length);
      expect(
        (exported.totals.single.value as ReportExportCountCell).value,
        report.totalTrips,
      );
    });
  }

  test('empty grouped export has zero rows and zero total', () {
    final groups = aggregator.group(
      rows: const <OperationalTripReportRow>[],
      dimension: OperationalReportDimension.driver,
    );
    final projected = projector.project(
      ReportExportDocument(
        companyId: 'company-a',
        companyName: 'Tenant A',
        logoBytes: null,
        kind: ReportExportKind.tripsByDriver,
        dateRange: const ReportDateRange(),
        generatedAtUtc: DateTime.utc(2026, 11, 21),
        content: ReportExportOperationalContent(
          OperationalTripReport(
            metadata: metadata,
            dimension: OperationalReportDimension.driver,
            groups: groups,
          ),
        ),
      ),
    );
    expect(projected.rows, isEmpty);
    expect((projected.totals.single.value as ReportExportCountCell).value, 0);
  });
}
