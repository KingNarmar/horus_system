abstract final class ReportsFailureCodes {
  static const permissionExport = 'reports.permission.export';
  static const pdfRenderUnavailable = 'reports.export.pdf_render_unavailable';
  static const pdfSaveUnavailable = 'reports.export.pdf_save_unavailable';
  static const pdfPrintUnavailable = 'reports.export.pdf_print_unavailable';
  static const pdfShareUnavailable = 'reports.export.pdf_share_unavailable';
  static const pdfInvalidDocument = 'reports.export.pdf_invalid_document';
  static const permissionOperationalView =
      'reports.permission.operational_view';
  static const permissionFinancialView = 'reports.permission.financial_view';
  static const permissionOpenInvoicesView =
      'reports.permission.open_invoices_view';

  static const validationDateRange = 'reports.validation.date_range';

  static const conflictSourceInvalid = 'reports.conflict.source_invalid';
  static const conflictCurrencyMismatch = 'reports.conflict.currency_mismatch';
  static const conflictFinancialDataInvalid =
      'reports.conflict.financial_data_invalid';
  static const conflictInvoiceBalanceInvalid =
      'reports.conflict.invoice_balance_invalid';
}
