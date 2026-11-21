/// A non-UI progress signal for report export orchestration.
///
/// Source-page counts are populated only by a verified, paginated source.
/// An unknown total must remain indeterminate.
enum ReportExportStage {
  readingSource,
  loadingBranding,
  renderingPdf,
  delivering,
}

final class ReportExportProgress {
  final ReportExportStage stage;
  final int? loadedRows;
  final int? totalRows;

  const ReportExportProgress({
    required this.stage,
    this.loadedRows,
    this.totalRows,
  }) : assert(loadedRows == null || loadedRows >= 0),
       assert(totalRows == null || totalRows >= 0),
       assert(
         loadedRows == null || totalRows == null || loadedRows <= totalRows,
       );

  bool get hasMeasuredRows => loadedRows != null && totalRows != null;
}

typedef ReportExportProgressCallback = void Function(ReportExportProgress);
