import '../../../../core/utils/result.dart';
import '../entities/company_invoice_settings.dart';
import '../value_objects/invoice_prefix.dart';

abstract interface class InvoiceSettingsRepository {
  Future<Result<CompanyInvoiceSettings?>> get({required String companyId});

  Future<Result<CompanyInvoiceSettings>> update({
    required String companyId,
    required InvoicePrefix prefix,
  });
}
