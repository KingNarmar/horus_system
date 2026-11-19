import '../entities/report_export_kind.dart';

/// Filenames contain only controlled ASCII tokens, not tenant/user text.
abstract final class ReportExportFileNamePolicy {
  static const prefix = 'horus_report';

  static String pdf({
    required ReportExportKind kind,
    required DateTime generatedAtUtc,
  }) => '${prefix}_${kind.name}_${generatedAtUtc.toUtc().millisecondsSinceEpoch}.pdf';
}
