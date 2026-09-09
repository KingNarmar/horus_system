import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/entities/current_company_context.dart';
import 'package:horus_system/features/company/domain/failures/company_failure_codes.dart';
import 'package:horus_system/features/company/domain/repositories/company_financial_settings_repository.dart';
import 'package:horus_system/features/company/domain/usecases/update_company_financial_configuration_usecase.dart';
import 'package:horus_system/features/company/presentation/cubit/company_financial_settings_cubit.dart';
import 'package:horus_system/features/company/presentation/cubit/company_financial_settings_state.dart';

void main() {
  test('saves normalized financial configuration for the current company', () async {
    final repository = _FakeFinancialSettingsRepository();
    final cubit = CompanyFinancialSettingsCubit(
      updateUseCase: UpdateCompanyFinancialConfigurationUseCase(repository),
    );
    addTearDown(cubit.close);

    await cubit.update(
      currentCompanyContext: _context,
      baseCurrencyCode: ' aed ',
      baseCurrencyFractionDigits: 2,
    );

    expect(cubit.state, isA<CompanyFinancialSettingsSaved>());
    expect(repository.companyId, 'company-1');
    expect(repository.baseCurrencyCode, 'AED');
    expect(repository.baseCurrencyFractionDigits, 2);
    final saved = cubit.state as CompanyFinancialSettingsSaved;
    expect(saved.company.baseCurrencyCode, 'AED');
  });

  test('exposes typed failures from the domain boundary', () async {
    final repository = _FakeFinancialSettingsRepository(
      result: const FailureResult<Company>(
        ConflictFailure(code: CompanyFailureCodes.conflictBaseCurrencyLocked),
      ),
    );
    final cubit = CompanyFinancialSettingsCubit(
      updateUseCase: UpdateCompanyFinancialConfigurationUseCase(repository),
    );
    addTearDown(cubit.close);

    await cubit.update(
      currentCompanyContext: _context,
      baseCurrencyCode: 'USD',
      baseCurrencyFractionDigits: 2,
    );

    expect(cubit.state, isA<CompanyFinancialSettingsFailure>());
    expect(
      (cubit.state as CompanyFinancialSettingsFailure).failure.code,
      CompanyFailureCodes.conflictBaseCurrencyLocked,
    );
  });
}

const _context = CurrentCompanyContext(
  company: Company(id: 'company-1', name: 'Horus Transport'),
  role: CompanyRole.owner,
);

final class _FakeFinancialSettingsRepository
    implements CompanyFinancialSettingsRepository {
  final Result<Company>? result;
  String? companyId;
  String? baseCurrencyCode;
  int? baseCurrencyFractionDigits;

  _FakeFinancialSettingsRepository({this.result});

  @override
  Future<Result<Company>> update({
    required String companyId,
    required String baseCurrencyCode,
    required int baseCurrencyFractionDigits,
  }) async {
    this.companyId = companyId;
    this.baseCurrencyCode = baseCurrencyCode;
    this.baseCurrencyFractionDigits = baseCurrencyFractionDigits;

    return result ??
        Success(
          Company(
            id: companyId,
            name: 'Horus Transport',
            baseCurrencyCode: baseCurrencyCode,
            baseCurrencyFractionDigits: baseCurrencyFractionDigits,
            businessTimezone: 'Asia/Dubai',
          ),
        );
  }
}
