import 'package:test/test.dart';
import 'package:horus_system/features/reports/data/models/report_export_snapshot_model.dart';

void main() {
  Map<String, Object?> source() => {
    'snapshot_id': 'snapshot-a',
    'snapshot_token': 'snapshot-a',
    'source_kind': 'trip_net_profit',
    'source_header': {
      'company': {
        'company_id': 'company-a',
        'base_currency_code': 'AED',
        'base_currency_fraction_digits': 2,
        'business_timezone': 'Asia/Dubai',
        'business_date': '2026-11-21',
      },
      'period': {'from_date': null, 'to_date': null},
      'validation': {'freight_precision_loss_count': 0},
    },
    'stream_counts': {'trips': 1300, 'expenses': 1300},
  };

  test('parses bounded immutable snapshot metadata', () {
    final model = ReportExportSnapshotModel.fromMap(source());
    expect(model.companyId, 'company-a');
    expect(model.sourceKind, 'trip_net_profit');
    expect(model.countFor('trips'), 1300);
    expect(model.countFor('expenses'), 1300);
    expect(() => model.streamCounts['other'] = 2, throwsUnsupportedError);
  });

  test('rejects mismatched snapshot token or missing company', () {
    final badToken = source()..['snapshot_token'] = 'wrong';
    expect(
      () => ReportExportSnapshotModel.fromMap(badToken),
      throwsFormatException,
    );
    final missingCompany = source()..remove('source_header');
    expect(
      () => ReportExportSnapshotModel.fromMap(missingCompany),
      throwsFormatException,
    );
  });

  test('parses page and rejects invalid counts', () {
    final page = ReportExportSnapshotPageModel.fromMap({
      'snapshot_token': 'snapshot-a',
      'stream': 'trips',
      'total_rows': 3,
      'rows': [
        {'trip_id': 'one'},
        {'trip_id': 'two'},
      ],
      'next_cursor': 'cursor-2',
    });
    expect(page.rows, hasLength(2));
    expect(page.nextCursor, 'cursor-2');
    expect(
      () => ReportExportSnapshotPageModel.fromMap({
        'snapshot_token': 'snapshot-a',
        'stream': 'trips',
        'total_rows': -1,
        'rows': [],
        'next_cursor': null,
      }),
      throwsFormatException,
    );
  });
}
