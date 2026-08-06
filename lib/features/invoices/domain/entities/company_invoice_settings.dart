import '../value_objects/invoice_prefix.dart';

final class CompanyInvoiceSettings {
  final String companyId;
  final InvoicePrefix prefix;

  const CompanyInvoiceSettings({required this.companyId, required this.prefix});
}
