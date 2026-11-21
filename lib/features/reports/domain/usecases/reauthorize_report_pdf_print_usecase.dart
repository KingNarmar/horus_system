import '../../../../core/utils/result.dart';
import 'prepare_report_export_usecase.dart';

/// Rechecks the current server-authorized company report before printing the
/// exact, already previewed PDF bytes. No PDF rebuild can change the preview.
final class ReauthorizeReportPdfPrintUseCase {
  final PrepareReportExportUseCase _prepare;

  const ReauthorizeReportPdfPrintUseCase(this._prepare);

  Future<Result<void>> call(PrepareReportExportParams params) async {
    final authorized = await _prepare(params);
    final failure = authorized.failureOrNull;
    if (failure != null) return FailureResult(failure);
    return const Success<void>(null);
  }
}
