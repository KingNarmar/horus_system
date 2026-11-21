import 'package:test/test.dart';

import 'package:horus_system/core/config/app_environment.dart';
import 'package:horus_system/core/domain/value_objects/business_date.dart';
import 'package:horus_system/features/reports/data/datasources/report_export_snapshot_remote_data_source.dart';
import 'package:horus_system/features/reports/data/models/report_export_snapshot_model.dart';
import 'package:horus_system/features/reports/data/repositories/paged_reports_repository_impl.dart';
import 'package:horus_system/features/reports/di/reports_dependencies.dart';
import 'package:horus_system/features/reports/domain/entities/report_export_cancellation.dart';

void main() {
  test('staging and production never enable development snapshot RPCs', () {
    final remote = _UnexpectedRemote();
    for (final environment in [
      AppEnvironment.staging,
      AppEnvironment.production,
    ]) {
      expect(
        ReportsDependencies.createSnapshotExportSourcesFactory(
          environment: environment,
          remote: remote,
        ),
        isNull,
      );
    }
  });

  test('development creates a separate paged repository per export', () {
    final remote = _UnexpectedRemote();
    final factory = ReportsDependencies.createSnapshotExportSourcesFactory(
      environment: AppEnvironment.development,
      remote: remote,
    );

    expect(factory, isNotNull);
    final first = factory!(cancellation: ReportExportCancellation());
    final second = factory(cancellation: ReportExportCancellation());

    expect(first, isA<PagedReportsRepositoryImpl>());
    expect(second, isA<PagedReportsRepositoryImpl>());
    expect(identical(first, second), isFalse);
  });
}

/// A source contract stub: dependency selection must not perform I/O.
final class _UnexpectedRemote implements ReportExportSnapshotRemoteDataSource {
  @override
  Future<ReportExportSnapshotModel> start({
    required String companyId,
    required String sourceKind,
    required BusinessDate? fromDate,
    required BusinessDate? toDate,
  }) => throw StateError('Export source selection must not start a snapshot.');

  @override
  Future<ReportExportSnapshotPageModel> read({
    required String snapshotId,
    required String stream,
    required String? cursor,
    required int pageSize,
  }) => throw StateError('Export source selection must not read a page.');

  @override
  Future<bool> release(String snapshotId) =>
      throw StateError('Export source selection must not release a snapshot.');
}
