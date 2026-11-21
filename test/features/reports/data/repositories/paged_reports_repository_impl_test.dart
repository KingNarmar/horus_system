import 'package:test/test.dart';

import 'package:horus_system/core/data/utils/db_date.dart';
import 'package:horus_system/core/domain/value_objects/business_date.dart';
import 'package:horus_system/features/reports/data/datasources/report_export_snapshot_remote_data_source.dart';
import 'package:horus_system/features/reports/data/models/report_export_snapshot_model.dart';
import 'package:horus_system/features/reports/data/repositories/paged_reports_repository_impl.dart';
import 'package:horus_system/features/reports/domain/entities/report_export_cancellation.dart';
import 'package:horus_system/features/reports/domain/entities/report_export_progress.dart';
import 'package:horus_system/features/reports/domain/failures/reports_failure_codes.dart';

void main() {
  test('reads a frozen source across two pages and releases once', () async {
    final remote = _FakeRemote();
    final progress = <ReportExportProgress>[];
    final repository = PagedReportsRepositoryImpl(
      remote: remote,
      cancellation: ReportExportCancellation(),
      onProgress: progress.add,
    );
    final result = await repository.getOperationalTripSource(
      companyId: 'company-a',
      fromDate: null,
      toDate: null,
    );
    expect(result.failureOrNull, isNull);
    expect(
      result.dataOrNull!.rows.map((row) => row.tripId),
      ['trip-a', 'trip-b'],
    );
    expect(remote.startCalls, 1);
    expect(remote.readCalls, 2);
    expect(remote.releaseCalls, 1);
    expect(progress.last.totalRows, 2);
    expect(progress.last.loadedRows, 2);
  });

  test('rejects unexpected snapshot tenant without exposing rows', () async {
    final remote = _FakeRemote(companyId: 'company-b');
    final repository = PagedReportsRepositoryImpl(
      remote: remote,
      cancellation: ReportExportCancellation(),
    );
    final result = await repository.getOperationalTripSource(
      companyId: 'company-a',
      fromDate: null,
      toDate: null,
    );
    expect(
      result.failureOrNull?.code,
      ReportsFailureCodes.conflictSourceInvalid,
    );
    expect(remote.readCalls, 0);
    expect(remote.releaseCalls, 1);
  });

  test('rejects duplicate row IDs and never returns partial export', () async {
    final remote = _FakeRemote(duplicateSecond: true);
    final repository = PagedReportsRepositoryImpl(
      remote: remote,
      cancellation: ReportExportCancellation(),
    );
    final result = await repository.getOperationalTripSource(
      companyId: 'company-a',
      fromDate: null,
      toDate: null,
    );
    expect(
      result.failureOrNull?.code,
      ReportsFailureCodes.conflictSourceInvalid,
    );
    expect(remote.releaseCalls, 1);
  });

  test('cancelled page run discards results and releases snapshot', () async {
    final cancellation = ReportExportCancellation();
    final remote = _FakeRemote();
    final repository = PagedReportsRepositoryImpl(
      remote: remote,
      cancellation: cancellation,
      onProgress: (progress) {
        if (progress.loadedRows == 1) cancellation.cancel();
      },
    );
    final result = await repository.getOperationalTripSource(
      companyId: 'company-a',
      fromDate: null,
      toDate: null,
    );
    expect(result.failureOrNull?.code, ReportsFailureCodes.exportCancelled);
    expect(remote.readCalls, 1);
    expect(remote.releaseCalls, 1);
  });

  test('empty financial report keeps source counters and metadata', () async {
    final remote = _FakeRemote(financial: true);
    final repository = PagedReportsRepositoryImpl(
      remote: remote,
      cancellation: ReportExportCancellation(),
    );
    final result = await repository.getTripExpensesSource(
      companyId: 'company-a',
      fromDate: BusinessDate(year: 2026, month: 11, day: 21),
      toDate: BusinessDate(year: 2026, month: 11, day: 21),
    );
    expect(result.failureOrNull, isNull);
    expect(result.dataOrNull!.rows, isEmpty);
    expect(result.dataOrNull!.negativeAmountCount, 0);
    expect(result.dataOrNull!.metadata.currency.value, 'AED');
    expect(remote.releaseCalls, 1);
  });
}

final class _FakeRemote implements ReportExportSnapshotRemoteDataSource {
  final String companyId;
  final bool duplicateSecond;
  final bool financial;
  int startCalls = 0;
  int readCalls = 0;
  int releaseCalls = 0;

  _FakeRemote({
    this.companyId = 'company-a',
    this.duplicateSecond = false,
    this.financial = false,
  });

  @override
  Future<ReportExportSnapshotModel> start({
    required String companyId,
    required String sourceKind,
    required BusinessDate? fromDate,
    required BusinessDate? toDate,
  }) async {
    startCalls++;
    return ReportExportSnapshotModel.fromMap({
      'snapshot_id': 'snapshot-a',
      'snapshot_token': 'snapshot-a',
      'source_kind': sourceKind,
      'source_header': {
        'company': {
          'company_id': this.companyId,
          'base_currency_code': 'AED',
          'base_currency_fraction_digits': 2,
          'business_timezone': 'Asia/Dubai',
          'business_date': '2026-11-21',
          'source_as_of_utc': '2026-11-21T09:00:00Z',
        },
        'period': {
          'from_date': DbDate.encodeNullable(fromDate),
          'to_date': DbDate.encodeNullable(toDate),
        },
        if (financial)
          'validation': {
            'precision_loss_count': 0,
            'negative_amount_count': 0,
            'currency_mismatch_count': 0,
          },
      },
      'stream_counts': {'rows': financial ? 0 : 2},
    });
  }

  @override
  Future<ReportExportSnapshotPageModel> read({
    required String snapshotId,
    required String stream,
    required String? cursor,
    required int pageSize,
  }) async {
    readCalls++;
    final first = cursor == null;
    return ReportExportSnapshotPageModel.fromMap({
      'snapshot_token': snapshotId,
      'stream': stream,
      'total_rows': financial ? 0 : 2,
      'rows': financial
          ? <Object>[]
          : [_trip(first ? 'trip-a' : (duplicateSecond ? 'trip-a' : 'trip-b'))],
      'next_cursor': financial || !first ? null : 'next-page',
    });
  }

  @override
  Future<bool> release(String snapshotId) async {
    releaseCalls++;
    return true;
  }
}

Map<String, Object?> _trip(String id) => {
  'trip_id': id,
  'trip_number': id,
  'operational_date': '2026-11-21',
  'status': 'created',
  'customer_id': 'customer-a',
  'customer_name': 'Customer A',
  'driver_id': null,
  'driver_name': null,
  'tractor_head_id': null,
  'tractor_head_plate_number': null,
  'trailer_id': null,
  'trailer_plate_number': null,
  'route_id': 'route-a',
  'loading_location': 'Warehouse',
  'unloading_location': 'Port',
  'loading_order_number': null,
  'waybill_number': null,
  'cargo_type': null,
  'quantity_tons': null,
};
