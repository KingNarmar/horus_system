import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure_codes.dart';
import '../../../../core/utils/result.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../../../company/domain/failures/company_failure_codes.dart';
import '../../../company/domain/policies/company_financial_readiness_policy.dart';
import '../../../company/domain/repositories/company_branding_repository.dart';
import '../entities/invoice.dart';
import '../entities/invoice_pdf_document.dart';
import '../entities/invoice_status.dart';
import '../failures/invoice_failure_codes.dart';
import '../policies/invoices_permission_policy.dart';
import '../repositories/invoices_repository.dart';

final class PrepareInvoicePdfParams {
  final CurrentCompanyContext currentCompanyContext;
  final String invoiceId;

  const PrepareInvoicePdfParams({
    required this.currentCompanyContext,
    required this.invoiceId,
  });
}

/// Reads backend-authoritative financial lines, and picks the correct issuer.
/// Issued identity must NEVER fall back to the mutable company profile.
final class PrepareInvoicePdfUseCase {
  final InvoicesRepository _invoices;
  final CompanyBrandingRepository _branding;

  const PrepareInvoicePdfUseCase({
    required InvoicesRepository invoices,
    required CompanyBrandingRepository branding,
  }) : _invoices = invoices,
       _branding = branding;

  Future<Result<InvoicePdfDocument>> call(
    PrepareInvoicePdfParams params,
  ) async {
    final context = params.currentCompanyContext;
    if (!InvoicesPermissionPolicy.canViewInvoices(context.role)) {
      return const FailureResult(
        PermissionFailure(code: FailureCodes.permissionInvoicesView),
      );
    }

    final invoiceId = params.invoiceId.trim();
    if (invoiceId.isEmpty) {
      return const FailureResult(
        ValidationFailure(code: FailureCodes.validationInvoiceIdRequired),
      );
    }

    final readiness = CompanyFinancialReadinessPolicy.evaluate(context.company);
    final configuration = readiness.configuration;
    if (!readiness.isReady || configuration == null) {
      return const FailureResult(
        ConflictFailure(
          code: CompanyFailureCodes.conflictFinancialSettingsNotConfigured,
        ),
      );
    }

    final result = await _invoices.getInvoiceDetails(
      companyId: context.companyId,
      invoiceId: invoiceId,
    );
    if (result is FailureResult<Invoice>) {
      return FailureResult(result.failure);
    }
    final invoice = (result as Success<Invoice>).data;
    if (invoice.companyId != context.companyId ||
        invoice.customer.companyId != context.companyId) {
      return const FailureResult(
        PermissionFailure(code: FailureCodes.permissionInvoicesView),
      );
    }

    InvoicePdfIssuerIdentity issuer;
    if (invoice.status == InvoiceStatus.draft) {
      final brandResult = await _branding.getProfile(context.companyId);
      if (brandResult.failureOrNull != null) {
        return FailureResult(brandResult.failureOrNull!);
      }
      final brand = brandResult.dataOrNull!;
      if (brand.companyId != context.companyId) {
        return const FailureResult(
          PermissionFailure(code: FailureCodes.permissionInvoicesView),
        );
      }
      issuer = InvoicePdfIssuerIdentity(
        name: brand.name,
        businessType: brand.businessType,
        phone: brand.phone,
        email: brand.email,
        address: brand.address,
        city: brand.city,
        country: brand.country,
        taxRegistrationNumber: brand.taxRegistrationNumber,
        logoPath: brand.logoPath,
      );
    } else {
      final snapshot = invoice.issuerSnapshot;
      if (snapshot == null) {
        return const FailureResult(
          ServerFailure(code: InvoiceFailureCodes.pdfIssuerSnapshotMissing),
        );
      }
      issuer = InvoicePdfIssuerIdentity(
        name: snapshot.companyName,
        businessType: snapshot.businessType,
        phone: snapshot.phone,
        email: snapshot.email,
        address: snapshot.address,
        city: snapshot.city,
        country: snapshot.country,
        taxRegistrationNumber: snapshot.taxRegistrationNumber,
        logoPath: snapshot.logoPath,
        snapshotSource: snapshot.source,
      );
    }

    final path = issuer.logoPath;
    if (path == null) {
      return Success(
        InvoicePdfDocument(
          invoice: invoice,
          issuer: issuer,
          currencyFractionDigits: configuration.fractionDigits,
        ),
      );
    }

    final logoResult = await _branding.downloadLogo(
      companyId: context.companyId,
      storagePath: path,
    );
    if (logoResult.failureOrNull != null) {
      return FailureResult(logoResult.failureOrNull!);
    }
    return Success(
      InvoicePdfDocument(
        invoice: invoice,
        issuer: issuer,
        logoBytes: logoResult.dataOrNull,
        currencyFractionDigits: configuration.fractionDigits,
      ),
    );
  }
}
