import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/entities/current_company_context.dart';
import 'package:horus_system/features/invoices/domain/entities/company_invoice_settings.dart';
import 'package:horus_system/features/invoices/domain/failures/invoice_failure_codes.dart';
import 'package:horus_system/features/invoices/domain/repositories/invoice_settings_repository.dart';
import 'package:horus_system/features/invoices/domain/usecases/invoice_settings_usecases.dart';
import 'package:horus_system/features/invoices/domain/value_objects/invoice_prefix.dart';
import 'package:test/test.dart';

void main() {
  group('GetInvoiceSettingsUseCase', () {
    test('rejects roles that cannot view invoices', () async {
      final repository = _FakeInvoiceSettingsRepository();
      final result = await GetInvoiceSettingsUseCase(repository)(
        GetInvoiceSettingsParams(
          currentCompanyContext: _context(CompanyRole.driver),
        ),
      );

      expect(result.failureOrNull?.code, FailureCodes.permissionInvoicesView);
      expect(repository.getCalls, 0);
    });

    test('scopes settings reads to the current company', () async {
      final repository = _FakeInvoiceSettingsRepository();
      await GetInvoiceSettingsUseCase(repository)(
        GetInvoiceSettingsParams(
          currentCompanyContext: _context(CompanyRole.viewer),
        ),
      );

      expect(repository.getCalls, 1);
      expect(repository.companyId, 'company-1');
    });
  });

  group('UpdateInvoiceSettingsUseCase', () {
    test('rejects roles that cannot manage company settings', () async {
      final repository = _FakeInvoiceSettingsRepository();
      final result = await UpdateInvoiceSettingsUseCase(repository)(
        UpdateInvoiceSettingsParams(
          currentCompanyContext: _context(CompanyRole.accountant),
          prefix: 'INV',
        ),
      );

      expect(
        result.failureOrNull?.code,
        InvoiceFailureCodes.permissionSettingsManagement,
      );
      expect(repository.updateCalls, 0);
    });

    test('rejects invalid prefixes', () async {
      final repository = _FakeInvoiceSettingsRepository();
      final result = await UpdateInvoiceSettingsUseCase(repository)(
        UpdateInvoiceSettingsParams(
          currentCompanyContext: _context(CompanyRole.owner),
          prefix: '26 invoices',
        ),
      );

      expect(
        result.failureOrNull?.code,
        InvoiceFailureCodes.validationPrefixInvalid,
      );
      expect(repository.updateCalls, 0);
    });

    test('normalizes prefix and scopes update to current company', () async {
      final repository = _FakeInvoiceSettingsRepository();
      final result = await UpdateInvoiceSettingsUseCase(repository)(
        UpdateInvoiceSettingsParams(
          currentCompanyContext: _context(CompanyRole.admin),
          prefix: ' horus-inv ',
        ),
      );

      expect(result, isA<Success<CompanyInvoiceSettings>>());
      expect(repository.companyId, 'company-1');
      expect(repository.prefix?.value, 'HORUS-INV');
    });
  });
}

CurrentCompanyContext _context(CompanyRole role) {
  return CurrentCompanyContext(
    company: const Company(id: 'company-1', name: 'Company'),
    role: role,
  );
}

final class _FakeInvoiceSettingsRepository
    implements InvoiceSettingsRepository {
  int getCalls = 0;
  int updateCalls = 0;
  String? companyId;
  InvoicePrefix? prefix;

  @override
  Future<Result<CompanyInvoiceSettings?>> get({
    required String companyId,
  }) async {
    getCalls++;
    this.companyId = companyId;
    return const Success<CompanyInvoiceSettings?>(null);
  }

  @override
  Future<Result<CompanyInvoiceSettings>> update({
    required String companyId,
    required InvoicePrefix prefix,
  }) async {
    updateCalls++;
    this.companyId = companyId;
    this.prefix = prefix;
    return Success(
      CompanyInvoiceSettings(companyId: companyId, prefix: prefix),
    );
  }
}
