import 'package:test/test.dart';

import 'package:horus_system/core/domain/value_objects/business_date.dart';
import 'package:horus_system/features/reports/data/datasources/report_export_snapshot_remote_data_source.dart';
import 'package:horus_system/features/reports/data/models/report_export_snapshot_model.dart';
import 'package:horus_system/features/reports/data/repositories/paged_reports_repository_impl.dart';
import 'package:horus_system/features/reports/domain/entities/report_export_cancellation.dart';
import 'package:horus_system/features/reports/domain/entities/report_export_progress.dart';

void main() {
  test('net profit preserves both financial streams and minor units', () async {
    final remote = _FinancialSnapshotRemote();
    final progress = <ReportExportProgress>[];
    final repo = PagedReportsRepositoryImpl(
      remote: remote,
      cancellation: ReportExportCancellation(),
      onProgress: progress.add,
    );

    final result = await repo.getTripNetProfitSource(
      companyId: 'company-a',
      fromDate: null,
      toDate: null,
    );
    expect(result.failureOrNull, isNull);
    final source = result.dataOrNull!;
    expect(source.trips, hasLength(1));
    expect(source.expenses, hasLength(2));
    expect(source.trips.single.freight.minorUnits, 123456);
    expect(source.expenses.first.amount.minorUnits, 23456);
    expect(source.expenses.last.amount.minorUnits, 100);
    expect(source.metadata.businessTimezone, 'Asia/Dubai');
    expect(source.metadata.sourceAsOfUtc, DateTime.utc(2026, 11, 21, 7));
    expect(source.freightPrecisionLossCount, 0);
    expect(progress.last.loadedRows, 3);
    expect(progress.last.totalRows, 3);
    expect(remote.startCalls, 1);
    expect(remote.readCalls, 2);
    expect(remote.releaseCalls, 1);
  });

  test('open invoices retains linked invoice and payment money', () async {
    final remote = _FinancialSnapshotRemote();
    final repo = PagedReportsRepositoryImpl(
      remote: remote,
      cancellation: ReportExportCancellation(),
    );

    final result = await repo.getOpenInvoicesSource(
      companyId: 'company-a',
      fromDate: BusinessDate(year: 2026, month: 11, day: 21),
      toDate: BusinessDate(year: 2026, month: 11, day: 21),
    );
    expect(result.failureOrNull, isNull);
    final source = result.dataOrNull!;
    expect(source.invoices, hasLength(1));
    expect(source.payments, hasLength(1));
    expect(source.invoices.single.total.minorUnits, 150000);
    expect(source.invoices.single.invoiceId, 'invoice-a');
    expect(source.payments.single.invoiceId, 'invoice-a');
    expect(source.payments.single.amount.minorUnits, 50000);
    expect(source.metadata.fromDate, BusinessDate(year: 2026, month: 11, day: 21));
    expect(source.metadata.toDate, BusinessDate(year: 2026, month: 11, day: 21));
    expect(remote.startCalls, 1);
    expect(remote.readCalls, 2);
    expect(remote.releaseCalls, 1);
  });
}

final class _FinancialSnapshotRemote implements ReportExportSnapshotRemoteDataSource {
  int startCalls = 0;
  int readCalls = 0;
  int releaseCalls = 0;
  String? _sourceKind;

  @override
  Future<ReportExportSnapshotModel> start({
    required String companyId,
    required String sourceKind,
    required BusinessDate? fromDate,
    required BusinessDate? toDate,
  }) async {
    startCalls++;
    _sourceKind = sourceKind;
    return ReportExportSnapshotModel.fromMap({
      'snapshot_id': 'snapshot-a',
      'snapshot_token': 'snapshot-a',
      'source_kind': sourceKind,
      'source_header': {
        'company': {
          'company_id': companyId,
          'base_currency_code': 'AED',
          'base_currency_fraction_digits': 2,
          'business_timezone': 'Asia/Dubai',
          'business_date': '2026-11-21',
          'source_as_of_utc': '2026-11-21T07:00:00Z',
        },
        'period': {
          'from_date': fromDate == null ? null : '2026-11-21',
          'to_date': toDate == null ? null : '2026-11-21',
        },
        'validation': sourceKind == 'trip_net_profit'
            ? {
                'freight_precision_loss_count': 0,
                'negative_freight_count': 0,
                'expense_precision_loss_count': 0,
                'negative_expense_count': 0,
                'expense_currency_mismatch_count': 0,
              }
            : {
                'invoice_currency_mismatch_count': 0,
                'payment_currency_mismatch_count': 0,
                'invalid_invoice_amount_count': 0,
                'invalid_payment_amount_count': 0,
                'missing_issue_date_count': 0,
              },
      },
      'stream_counts': sourceKind == 'trip_net_profit'
          ? {'trips': 1, 'expenses': 2}
          : {'invoices': 1, 'payments': 1},
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
    final isProfit = _sourceKind == 'trip_net_profit';
    final rows = switch (stream) {
      'trips' => [_trip()],
      'expenses' => [
        {'expense_id': 'expense-a', 'trip_id': 'trip-a', 'amount_minor_units': 23456},
        {'expense_id': 'expense-b', 'trip_id': 'trip-a', 'amount_minor_units': 100},
      ],
      'invoices' => [_invoice()],
      'payments' => [_payment()],
      _ => throw StateError('Unexpected stream $stream'),
    };
    return ReportExportSnapshotPageModel.fromMap({
      'snapshot_token': snapshotId,
      'stream': stream,
      'total_rows': isProfit && stream == 'expenses' ? 2 : 1,
      'rows': rows,
      'next_cursor': null,
    });
  }

  @override
  Future<bool> release(String snapshotId) async {
    releaseCalls++;
    return true;
  }
}

Map<String, Object?> _trip() => {
  'trip_id': 'trip-a',
  'trip_number': 'TRIP-1',
  'operational_date': '2026-11-21',
  'status': 'created',
  'customer_id': 'customer-a',
  'customer_name': 'Customer',
  'driver_id': null,
  'driver_name': null,
  'tractor_head_id': null,
  'tractor_head_plate_number': null,
  'trailer_id': null,
  'trailer_plate_number': null,
  'loading_location': 'Warehouse',
  'unloading_location': 'Port',
  'loading_order_number': null,
  'waybill_number': null,
  'freight_minor_units': 123456,
};

Map<String, Object?> _invoice() => {
  'invoice_id': 'invoice-a',
  'invoice_number': 'INV-1',
  'customer_id': 'customer-a',
  'customer_name': 'Customer',
  'status': 'issued',
  'currency_code': 'AED',
  'total_minor_units': 150000,
  'issue_date': '2026-11-21',
  'due_date': null,
  'issued_at': '2026-11-21T07:00:00Z',
};

Map<String, Object?> _payment() => {
  'payment_id': 'payment-a',
  'invoice_id': 'invoice-a',
  'currency_code': 'AED',
  'amount_minor_units': 50000,
  'payment_date': '2026-11-21',
  'created_at': '2026-11-21T07:00:00Z',
};
