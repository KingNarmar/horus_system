import '../../../../core/errors/common_failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/report_export_cancellation.dart';
import '../entities/report_export_progress.dart';
import '../entities/report_source_page.dart';
import '../failures/report_export_cancelled_failure.dart';
import '../failures/reports_failure_codes.dart';

/// Assembles a server-frozen source without silently losing rows.
///
/// Transport, cursor interpretation and access control stay in Data.
/// Domain verifies snapshot continuity, exact counts, unique IDs and
/// cancellation before exposing the source to financial calculations.
final class ReportSourcePageCollector {
  const ReportSourcePageCollector();

  Future<Result<List<T>>> collect<T>({
    required Future<Result<ReportSourcePage<T>>> Function(String? cursor)
    readPage,
    required String Function(T row) idOf,
    required ReportExportCancellation cancellation,
    ReportExportProgressCallback? onProgress,
  }) async {
    final rows = <T>[];
    final ids = <String>{};
    final cursors = <String>{};
    String? cursor;
    String? snapshotToken;
    int? expectedTotal;

    while (true) {
      if (cancellation.isCancelled) {
        return const FailureResult(ReportExportCancelledFailure());
      }

      final result = await readPage(cursor);
      if (cancellation.isCancelled) {
        return const FailureResult(ReportExportCancelledFailure());
      }
      final failure = result.failureOrNull;
      if (failure != null) return FailureResult(failure);
      final page = result.dataOrNull!;

      if (page.snapshotToken.trim().isEmpty ||
          page.totalRows < 0 ||
          (snapshotToken != null && snapshotToken != page.snapshotToken) ||
          (expectedTotal != null && expectedTotal != page.totalRows) ||
          rows.length + page.rows.length > page.totalRows ||
          (page.rows.isEmpty && page.nextCursor != null)) {
        return const FailureResult(
          ConflictFailure(code: ReportsFailureCodes.conflictSourceInvalid),
        );
      }

      snapshotToken ??= page.snapshotToken;
      expectedTotal ??= page.totalRows;

      for (final row in page.rows) {
        final id = idOf(row);
        if (id.trim().isEmpty || !ids.add(id)) {
          return const FailureResult(
            ConflictFailure(code: ReportsFailureCodes.conflictSourceInvalid),
          );
        }
        rows.add(row);
      }

      final next = page.nextCursor;
      if (next == null) {
        if (rows.length != expectedTotal) {
          return const FailureResult(
            ConflictFailure(code: ReportsFailureCodes.conflictSourceInvalid),
          );
        }
        onProgress?.call(
          ReportExportProgress(
            stage: ReportExportStage.readingSource,
            loadedRows: rows.length,
            totalRows: expectedTotal,
          ),
        );
        return Success(List.unmodifiable(rows));
      }

      if (next.trim().isEmpty ||
          next == cursor ||
          !cursors.add(next) ||
          rows.length == expectedTotal) {
        return const FailureResult(
          ConflictFailure(code: ReportsFailureCodes.conflictSourceInvalid),
        );
      }

      onProgress?.call(
        ReportExportProgress(
          stage: ReportExportStage.readingSource,
          loadedRows: rows.length,
          totalRows: expectedTotal,
        ),
      );
      cursor = next;
    }
  }
}
