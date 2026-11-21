import '../entities/report_export_cancellation.dart';
import '../entities/report_export_progress.dart';
import 'reports_repository.dart';

/// Creates a request-scoped, Domain-compatible source reader for one export.
///
/// Data can provide paginated snapshots without changing screen report reads
/// or reproducing any report business logic in Presentation.
typedef ReportExportSourcesFactory =
    ReportsRepository Function({
      required ReportExportCancellation cancellation,
      ReportExportProgressCallback? onProgress,
    });
