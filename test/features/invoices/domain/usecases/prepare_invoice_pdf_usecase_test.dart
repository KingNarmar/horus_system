import 'dart:typed_data';

import 'package:horus_system/core/domain/value_objects/currency_code.dart';
import 'package:horus_system/core/domain/value_objects/money.dart';
import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/entities/company_brand_profile.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/entities/current_company_context.dart';
import 'package:horus_system/features/company/domain/repositories/company_branding_repository.dart';
import 'package:horus_system/features/invoices/domain/entities/invoice.dart';
import 'package:horus_system/features/invoices/domain/entities/invoice_customer_snapshot.dart';
import 'package:horus_system/features/invoices/domain/entities/invoice_issuer_snapshot.dart';
import 'package:horus_system/features/invoices/domain/entities/invoice_status.dart';
import 'package:horus_system/features/invoices/domain/entities/invoice_totals.dart';
import 'package:horus_system/features/invoices/domain/entities/invoice_trip_line.dart';
import 'package:horus_system/features/invoices/domain/failures/invoice_failure_codes.dart';
import 'package:horus_system/features/invoices/domain/repositories/invoices_repository.dart';
import 'package:horus_system/features/invoices/domain/usecases/prepare_invoice_pdf_usecase.dart';
import 'package:horus_system/features/invoices/domain/value_objects/tax_rate.dart';
import 'package:test/test.dart';

void main() {
  test('rejects unauthorized export before reading financial data', () async {
    final invoices = _Invoices();
    final branding = _Branding();
    final result = await _prepare(invoices, branding)(
      PrepareInvoicePdfParams(
        currentCompanyContext: _context(CompanyRole.viewer),
        invoiceId: 'invoice-1',
      ),
    );

    expect(result.failureOrNull?.code, FailureCodes.permissionInvoicesView);
    expect(invoices.reads, 0);
    expect(branding.profileReads, 0);
  });

  test('issued invoice uses historical issuer and historical logo', () async {
    final invoices = _Invoices();
    final branding = _Branding();
    final result = await _prepare(invoices, branding)(
      PrepareInvoicePdfParams(
        currentCompanyContext: _context(CompanyRole.accountant),
        invoiceId: 'invoice-1',
      ),
    );

    expect(result.isSuccess, isTrue);
    expect(result.dataOrNull?.issuer.name, 'Original issuer');
    expect(result.dataOrNull?.issuer.logoPath, 'old-logo.png');
    expect(
      result.dataOrNull?.issuer.snapshotSource,
      InvoiceIssuerSnapshotSource.issuance,
    );
    expect(result.dataOrNull?.invoice.totals.grandTotal.minorUnits, 10000);
    expect(result.dataOrNull?.currencyFractionDigits, 2);
    expect(branding.profileReads, 0);
    expect(branding.lastLogoPath, 'old-logo.png');
  });

  test('draft explicitly uses current identity', () async {
    final invoices = _Invoices()..invoice = _invoice(InvoiceStatus.draft);
    final branding = _Branding();
    final result = await _prepare(invoices, branding)(
      PrepareInvoicePdfParams(
        currentCompanyContext: _context(CompanyRole.owner),
        invoiceId: 'invoice-1',
      ),
    );

    expect(result.dataOrNull?.issuer.name, 'Current company');
    expect(result.dataOrNull?.issuer.snapshotSource, isNull);
    expect(branding.profileReads, 1);
    expect(branding.lastLogoPath, 'current-logo.png');
  });

  test('no logo path renders without a storage download', () async {
    final invoices = _Invoices()
      ..invoice = _invoice(
        InvoiceStatus.paid,
        logoPath: null,
      );
    final branding = _Branding();
    final result = await _prepare(invoices, branding)(
      PrepareInvoicePdfParams(
        currentCompanyContext: _context(CompanyRole.admin),
        invoiceId: 'invoice-1',
      ),
    );

    expect(result.isSuccess, isTrue);
    expect(result.dataOrNull?.logoBytes, isNull);
    expect(branding.logoReads, 0);
    expect(branding.profileReads, 0);
  });

  test('issued invoice without snapshot refuses mutable fallback', () async {
    final invoices = _Invoices()
      ..invoice = _invoice(InvoiceStatus.issued, withSnapshot: false);
    final branding = _Branding();
    final result = await _prepare(invoices, branding)(
      PrepareInvoicePdfParams(
        currentCompanyContext: _context(CompanyRole.owner),
        invoiceId: 'invoice-1',
      ),
    );

    expect(
      result.failureOrNull?.code,
      InvoiceFailureCodes.pdfIssuerSnapshotMissing,
    );
    expect(branding.profileReads, 0);
    expect(branding.logoReads, 0);
  });

  test('foreign invoice returned by repository is rejected', () async {
    final invoices = _Invoices()
      ..invoice = _invoice(InvoiceStatus.issued, companyId: 'company-2');
    final branding = _Branding();
    final result = await _prepare(invoices, branding)(
      PrepareInvoicePdfParams(
        currentCompanyContext: _context(CompanyRole.owner),
        invoiceId: 'invoice-1',
      ),
    );

    expect(result.failureOrNull?.code, FailureCodes.permissionInvoicesView);
    expect(branding.logoReads, 0);
  });

  test('unauthorized private logo download denies export', () async {
    final invoices = _Invoices();
    final branding = _Branding()
      ..downloadResult = const FailureResult(
        PermissionFailure(code: FailureCodes.permissionInvoicesView),
      );
    final result = await _prepare(invoices, branding)(
      PrepareInvoicePdfParams(
        currentCompanyContext: _context(CompanyRole.owner),
        invoiceId: 'invoice-1',
      ),
    );

    expect(result.failureOrNull?.code, FailureCodes.permissionInvoicesView);
  });
}

PrepareInvoicePdfUseCase _prepare(_Invoices invoices, _Branding branding) {
  return PrepareInvoicePdfUseCase(invoices: invoices, branding: branding);
}

CurrentCompanyContext _context(CompanyRole role) {
  return CurrentCompanyContext(
    company: const Company(
      id: 'company-1',
      name: 'Current company',
      baseCurrencyCode: 'AED',
      baseCurrencyFractionDigits: 2,
      businessTimezone: 'Asia/Dubai',
    ),
    role: role,
  );
}

Invoice _invoice(
  InvoiceStatus status, {
  bool withSnapshot = true,
  String companyId = 'company-1',
  String? logoPath = 'old-logo.png',
}) {
  final currency = CurrencyCode.tryParse('AED')!;
  final zero = Money(minorUnits: 0, currency: currency);
  final amount = Money(minorUnits: 10000, currency: currency);
  return Invoice(
    id: 'invoice-1',
    companyId: companyId,
    customer: const InvoiceCustomerSnapshot(
      companyId: 'company-1',
      customerId: 'customer-1',
      name: 'Customer',
    ),
    status: status,
    currency: currency,
    lines: [InvoiceTripLine(tripId: 'trip-1', amount: amount)],
    totals: InvoiceTotals(
      subtotal: amount,
      discount: zero,
      taxableAmount: amount,
      taxRate: TaxRate.tryCreate(0)!,
      taxAmount: zero,
      grandTotal: amount,
    ),
    issuerSnapshot: status == InvoiceStatus.draft || !withSnapshot
        ? null
        : InvoiceIssuerSnapshot(
            companyName: 'Original issuer',
            logoPath: logoPath,
            source: InvoiceIssuerSnapshotSource.issuance,
            capturedAt: DateTime.utc(2026, 11, 17),
          ),
    createdAt: DateTime.utc(2026, 11, 17),
    updatedAt: DateTime.utc(2026, 11, 17),
  );
}

final class _Invoices extends Fake implements InvoicesRepository {
  Invoice invoice = _invoice(InvoiceStatus.issued);
  int reads = 0;

  @override
  Future<Result<Invoice>> getInvoiceDetails({
    required String companyId,
    required String invoiceId,
  }) async {
    reads++;
    return Success(invoice);
  }
}

final class _Branding extends Fake implements CompanyBrandingRepository {
  int profileReads = 0;
  int logoReads = 0;
  String? lastLogoPath;
  Result<Uint8List> downloadResult = Success(Uint8List.fromList([1, 2]));

  @override
  Future<Result<CompanyBrandProfile>> getProfile(String companyId) async {
    profileReads++;
    return Success(
      CompanyBrandProfile(
        companyId: companyId,
        name: 'Current company',
        logoPath: 'current-logo.png',
        updatedAt: DateTime.utc(2026, 11, 18),
      ),
    );
  }

  @override
  Future<Result<Uint8List>> downloadLogo({
    required String companyId,
    required String storagePath,
  }) async {
    logoReads++;
    lastLogoPath = storagePath;
    return downloadResult;
  }
}
