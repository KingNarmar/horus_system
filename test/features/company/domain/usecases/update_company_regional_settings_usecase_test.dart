import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/entities/current_company_context.dart';
import 'package:horus_system/features/company/domain/failures/company_failure_codes.dart';
import 'package:horus_system/features/company/domain/repositories/company_regional_settings_repository.dart';
import 'package:horus_system/features/company/domain/usecases/update_company_regional_settings_usecase.dart';
import 'package:test/test.dart';

void main() {
  group('UpdateCompanyRegionalSettingsUseCase', () {
    test('rejects roles that cannot manage company settings', () async {
      final repository = _FakeCompanyRegionalSettingsRepository();
      final result = await UpdateCompanyRegionalSettingsUseCase(repository)(
        _params(role: CompanyRole.accountant),
      );

      expect(
        result.failureOrNull?.code,
        CompanyFailureCodes.permissionSettingsManagement,
      );
      expect(repository.calls, 0);
    });

    test('rejects invalid currency codes', () async {
      final repository = _FakeCompanyRegionalSettingsRepository();
      final result = await UpdateCompanyRegionalSettingsUseCase(repository)(
        _params(baseCurrencyCode: 'dirham'),
      );

      expect(
        result.failureOrNull?.code,
        CompanyFailureCodes.validationBaseCurrencyInvalid,
      );
      expect(repository.calls, 0);
    });

    test('rejects unsupported currency precision', () async {
      final repository = _FakeCompanyRegionalSettingsRepository();
      final result = await UpdateCompanyRegionalSettingsUseCase(repository)(
        _params(baseCurrencyFractionDigits: 5),
      );

      expect(
        result.failureOrNull?.code,
        CompanyFailureCodes.validationBaseCurrencyFractionDigitsInvalid,
      );
      expect(repository.calls, 0);
    });

    test('requires a business timezone', () async {
      final repository = _FakeCompanyRegionalSettingsRepository();
      final result = await UpdateCompanyRegionalSettingsUseCase(repository)(
        _params(businessTimezone: '   '),
      );

      expect(
        result.failureOrNull?.code,
        CompanyFailureCodes.validationBusinessTimezoneRequired,
      );
      expect(repository.calls, 0);
    });

    test('normalizes values and scopes update to current company', () async {
      final repository = _FakeCompanyRegionalSettingsRepository();
      final result = await UpdateCompanyRegionalSettingsUseCase(repository)(
        _params(
          role: CompanyRole.admin,
          baseCurrencyCode: ' aed ',
          businessTimezone: ' Asia/Dubai ',
        ),
      );

      expect(result, isA<Success<Company>>());
      expect(repository.calls, 1);
      expect(repository.companyId, 'company-1');
      expect(repository.baseCurrencyCode, 'AED');
      expect(repository.baseCurrencyFractionDigits, 2);
      expect(repository.businessTimezone, 'Asia/Dubai');
    });
  });
}

UpdateCompanyRegionalSettingsParams _params({
  CompanyRole role = CompanyRole.owner,
  String baseCurrencyCode = 'AED',
  int baseCurrencyFractionDigits = 2,
  String businessTimezone = 'Asia/Dubai',
}) {
  return UpdateCompanyRegionalSettingsParams(
    currentCompanyContext: CurrentCompanyContext(
      company: const Company(id: 'company-1', name: 'Horus Transport'),
      role: role,
    ),
    baseCurrencyCode: baseCurrencyCode,
    baseCurrencyFractionDigits: baseCurrencyFractionDigits,
    businessTimezone: businessTimezone,
  );
}

final class _FakeCompanyRegionalSettingsRepository
    implements CompanyRegionalSettingsRepository {
  int calls = 0;
  String? companyId;
  String? baseCurrencyCode;
  int? baseCurrencyFractionDigits;
  String? businessTimezone;

  @override
  Future<Result<Company>> update({
    required String companyId,
    required String baseCurrencyCode,
    required int baseCurrencyFractionDigits,
    required String businessTimezone,
  }) async {
    calls++;
    this.companyId = companyId;
    this.baseCurrencyCode = baseCurrencyCode;
    this.baseCurrencyFractionDigits = baseCurrencyFractionDigits;
    this.businessTimezone = businessTimezone;

    return Success(
      Company(
        id: companyId,
        name: 'Horus Transport',
        baseCurrencyCode: baseCurrencyCode,
        baseCurrencyFractionDigits: baseCurrencyFractionDigits,
        businessTimezone: businessTimezone,
      ),
    );
  }
}
