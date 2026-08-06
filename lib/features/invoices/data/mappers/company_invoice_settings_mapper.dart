import '../../domain/entities/company_invoice_settings.dart';
import '../../domain/value_objects/invoice_prefix.dart';
import '../models/company_invoice_settings_model.dart';

extension CompanyInvoiceSettingsModelMapper on CompanyInvoiceSettingsModel {
  CompanyInvoiceSettings toEntity() {
    final prefix = InvoicePrefix.tryParse(invoicePrefix);
    if (prefix == null) {
      throw FormatException(
        'Invalid persisted invoice prefix: $invoicePrefix.',
      );
    }

    return CompanyInvoiceSettings(companyId: companyId, prefix: prefix);
  }
}
