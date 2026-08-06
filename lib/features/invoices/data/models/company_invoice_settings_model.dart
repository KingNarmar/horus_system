import '../../../../core/data/constants/db_common_fields.dart';
import '../constants/invoices_db_fields.dart';
import '../utils/invoice_data_parser.dart';

final class CompanyInvoiceSettingsModel {
  final String companyId;
  final String invoicePrefix;

  const CompanyInvoiceSettingsModel({
    required this.companyId,
    required this.invoicePrefix,
  });

  factory CompanyInvoiceSettingsModel.fromMap(Map<String, dynamic> map) {
    return CompanyInvoiceSettingsModel(
      companyId: InvoiceDataParser.requiredString(
        map[DbCommonFields.companyId],
        DbCommonFields.companyId,
      ),
      invoicePrefix: InvoiceDataParser.requiredString(
        map[InvoicesDbFields.invoicePrefix],
        InvoicesDbFields.invoicePrefix,
      ),
    );
  }
}
