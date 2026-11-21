import 'package:test/test.dart';

import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/reports/domain/entities/report_export_cancellation.dart';
import 'package:horus_system/features/reports/domain/entities/report_export_progress.dart';
import 'package:horus_system/features/reports/domain/entities/report_source_page.dart';
import 'package:horus_system/features/reports/domain/failures/reports_failure_codes.dart';
import 'package:horus_system/features/reports/domain/services/report_source_page_collector.dart';

void main() {
  const collector = ReportSourcePageCollector();

  test('collects 1,300 rows across bounded pages without omissions', () async {
    final cancellation = ReportExportCancellation();
    final progress = <ReportExportProgress>[];
    final result = await collector.collect<String>(
      readPage: (cursor) async {
        final offset = cursor == null ? 0 : int.parse(cursor);
        final end = offset + 200 > 1300 ? 1300 : offset + 200;
        return Success(
          ReportSourcePage(
            snapshotToken: 'snapshot-a',
            totalRows: 1300,
            rows: [
              for (var i = offset; i < end; i++) 'record-$i',
            ],
            nextCursor: end == 1300 ? null : '$end',
          ),
        );
      },
      idOf: (row) => row,
      cancellation: cancellation,
      onProgress: progress.add,
    );

    expect(result.failureOrNull, isNull);
    expect(result.dataOrNull, hasLength(1300));
    expect(result.dataOrNull!.toSet(), hasLength(1300));
    expect(progress.last.loadedRows, 1300);
    expect(progress.last.totalRows, 1300);
    expect(progress.last.stage, ReportExportStage.readingSource);
  });

  test('accepts a verified empty snapshot', () async {
    final result = await collector.collect<String>(
      readPage: (_) async => Success(
        ReportSourcePage(
          snapshotToken: 'empty-snapshot',
          totalRows: 0,
          rows: const [],
          nextCursor: null,
        ),
      ),
      idOf: (row) => row,
      cancellation: ReportExportCancellation(),
    );
    expect(result.dataOrNull, isEmpty);
  });

  test('fails on incomplete final page; never silently truncates', () async {
    final result = await collector.collect<String>(
      readPage: (_) async => Success(
        ReportSourcePage(
          snapshotToken: 'snapshot-a',
          totalRows: 3,
          rows: const ['first', 'second'],
          nextCursor: null,
        ),
      ),
      idOf: (row) => row,
      cancellation: ReportExportCancellation(),
    );
    expect(
      result.failureOrNull?.code,
      ReportsFailureCodes.conflictSourceInvalid,
    );
  });

  test('fails when a source snapshot changes between pages', () async {
    final result = await collector.collect<String>(
      readPage: (cursor) async => Success(
        ReportSourcePage(
          snapshotToken: cursor == null ? 'snapshot-a' : 'snapshot-b',
          totalRows: 2,
          rows: [cursor == null ? 'first' : 'second'],
          nextCursor: cursor == null ? 'next' : null,
        ),
      ),
      idOf: (row) => row,
      cancellation: ReportExportCancellation(),
    );
    expect(
      result.failureOrNull?.code,
      ReportsFailureCodes.conflictSourceInvalid,
    );
  });

  test('rejects repeated record IDs and cursor loops', () async {
    final repeated = await collector.collect<String>(
      readPage: (cursor) async => Success(
        ReportSourcePage(
          snapshotToken: 'snapshot-a',
          totalRows: 2,
          rows: const ['first'],
          nextCursor: cursor == null ? 'next' : null,
        ),
      ),
      idOf: (row) => row,
      cancellation: ReportExportCancellation(),
    );
    expect(
      repeated.failureOrNull?.code,
      ReportsFailureCodes.conflictSourceInvalid,
    );

    final cursorLoop = await collector.collect<String>(
      readPage: (_) async => Success(
        ReportSourcePage(
          snapshotToken: 'snapshot-a',
          totalRows: 4,
          rows: const ['first'],
          nextCursor: 'again',
        ),
      ),
      idOf: (row) => row,
      cancellation: ReportExportCancellation(),
    );
    expect(
      cursorLoop.failureOrNull?.code,
      ReportsFailureCodes.conflictSourceInvalid,
    );
  });

  test('cancellation stops later requests and discards partial rows', () async {
    final cancellation = ReportExportCancellation();
    var calls = 0;
    final result = await collector.collect<String>(
      readPage: (_) async {
        calls++;
        return Success(
          ReportSourcePage(
            snapshotToken: 'snapshot-a',
            totalRows: 2,
            rows: const ['first'],
            nextCursor: 'next',
          ),
        );
      },
      idOf: (row) => row,
      cancellation: cancellation,
      onProgress: (_) => cancellation.cancel(),
    );
    expect(calls, 1);
    expect(result.failureOrNull?.code, ReportsFailureCodes.exportCancelled);
  });
}
