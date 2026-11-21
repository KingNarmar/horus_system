/// Per-export app-private temporary file staging, never public Storage.
abstract final class ReportPdfShareConstants {
  static const rootDirectory = 'horus_report_pdf_shares';
  static const sessionPrefix = 'report_share_';
  static const mimeType = 'application/pdf';
  static const maxCacheAge = Duration(hours: 24);
  static final unsafeFileNameChars = RegExp(r'[^A-Za-z0-9._-]');
}
