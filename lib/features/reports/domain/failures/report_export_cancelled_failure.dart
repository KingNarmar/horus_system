import '../../../../core/errors/failure.dart';
import 'reports_failure_codes.dart';

/// Expected, silent cancellation rather than a permissions or server error.
final class ReportExportCancelledFailure extends Failure {
  const ReportExportCancelledFailure()
    : super(code: ReportsFailureCodes.exportCancelled);
}
