import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/entities/current_company_context.dart';
import 'package:horus_system/features/company/domain/failures/company_failure_codes.dart';
import 'package:horus_system/features/company/domain/repositories/company_financial_settings_repository.dart';
import 'package:horus_system/features/company/domain/usecases/update_company_financial_configuration_usecase.dart';
import 'package:test/test.dart';

void main() {
  group('UpdateCompanyFinancialConfigurationUseCase', () {
    test('rejects roles that cannot manage company settings', () async {
      final repository = _FakeCompanyFinancialSettingsRepository();
      final result = await UpdateCompanyFinancialConfigurationUseCase(repository)(
        _params(role: CompanyRole.accountant),
      );

      expect(
        result.failureOrNull?.code,
        CompanyFailureCodes.permissionSettingsManagement,
      );
      expect(repository.calls, 0);
    });

    test('rejects invalid currency codes', () async {
      final repository = _FakeCompanyFinancialSettingsRepository();
      final result = await UpdateCompanyFinancialConfigurationUseCase(repository)(
        _params(baseCurrencyCode: 'dirham'),
      );

      expect(
        result.failureOrNull?.code,
        CompanyFailureCodes.validationBaseCurrencyInvalid,
      );
      expect(repository.calls, 0);
    });

    test('rejects unsupported fraction digits', () async {
      final repository = _FakeCompanyFinancialSettingsRepository();
      final result = await UpdateCompanyFinancialConfigurationUseCase(repository)(
        _params(baseCurrencyFractionDigits: 5),
      );

      expect(
        result.failureOrNull?.code,
        CompanyFailureCodes.validationBaseCurrencyFractionDigitsInvalid,
      );
      expect(repository.calls, 0);
    });

    test('normalizes currency and scopes update to current company', () async {
      final repository = _FakeCompanyFinancialSettingsRepository();
      final result = await UpdateCompanyFinancialConfigurationUseCase(repository)(
        _params(role: CompanyRole.admin, baseCurrencyCode: ' aed '),
      );

      expect(result, isA<Success<Company>>());
      expect(repository.calls, 1);
      expect(repository.companyId, 'company-1');
      expect(repository.baseCurrencyCode, 'AED');
      expect(repository.baseCurrencyFractionDigits, 2);
    });
  });
}

UpdateCompanyFinancialConfigurationParams _params({
  CompanyRole role = CompanyRole.owner,
  String baseCurrencyCode = 'AED',
  int baseCurrencyFractionDigits = 2,
}) {
  return UpdateCompanyFinancialConfigurationParams(
    currentCompanyContext: CurrentCompanyContext(
      company: const Company(id: 'company-1', name: 'Horus Transport'),
      role: role,
    ),
    baseCurrencyCode: baseCurrencyCode,
    baseCurrencyFractionDigits: baseCurrencyFractionDigits,
  );
}

final class _FakeCompanyFinancialSettingsRepository
    implements CompanyFinancialSettingsRepository {
  int calls = 0;
  String? companyId;
  String? baseCurrencyCode;
  int? baseCurrencyFractionDigits;

  @override
  Future<Result<Company>> update({
    required String companyId,
    required String baseCurrencyCode,
    required int baseCurrencyFractionDigits,
  }) async {
    calls++;
    this.companyId = companyId;
    this.baseCurrencyCode = baseCurrencyCode;
    this.baseCurrencyFractionDigits = baseCurrencyFractionDigits;

    return Success(
      Company(
        id: companyId,
        name: 'Horus Transport',
        baseCurrencyCode: baseCurrencyCode,
        baseCurrencyFractionDigits: baseCurrencyFractionDigits,
      ),
    );
  }
}
