/// Private staging details for native sharing (not Supabase Storage).
abstract final class InvoicePdfShareConstants {
  static const rootDirectory = 'horus_invoice_pdf_shares';
  static const sessionPrefix = 'invoice_share_';
  static const mimeType = 'application/pdf';
  static const maxCacheAge = Duration(hours: 24);
  static final unsafeFileNameChars = RegExp(r'[^A-Za-z0-9._-]');
}
