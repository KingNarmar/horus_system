/// Request-scoped signal shared by report preparation and PDF rendering.
///
/// Cancelling cannot interrupt a pending source request or a platform dialog,
/// but it prevents any later export stages from starting.
final class ReportExportCancellation {
  bool _isCancelled = false;

  bool get isCancelled => _isCancelled;

  void cancel() => _isCancelled = true;
}
