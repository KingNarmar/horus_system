import '../../../../core/domain/value_objects/currency_code.dart';
import '../../../../core/errors/common_failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/company.dart';
import '../entities/company_financial_configuration.dart';
import '../entities/current_company_context.dart';
import '../failures/company_failure_codes.dart';
import '../repositories/company_financial_settings_repository.dart';

final class UpdateCompanyFinancialConfigurationParams {
  final CurrentCompanyContext currentCompanyContext;
  final String baseCurrencyCode;
  final int baseCurrencyFractionDigits;

  const UpdateCompanyFinancialConfigurationParams({
    required this.currentCompanyContext,
    required this.baseCurrencyCode,
    required this.baseCurrencyFractionDigits,
  });
}

final class UpdateCompanyFinancialConfigurationUseCase
    implements UseCase<Company, UpdateCompanyFinancialConfigurationParams> {
  final CompanyFinancialSettingsRepository _repository;

  const UpdateCompanyFinancialConfigurationUseCase(this._repository);

  @override
  Future<Result<Company>> call(
    UpdateCompanyFinancialConfigurationParams params,
  ) {
    final context = params.currentCompanyContext;
    if (!context.canManageCompany) {
      return Future.value(
        const FailureResult<Company>(
          PermissionFailure(
            code: CompanyFailureCodes.permissionSettingsManagement,
          ),
        ),
      );
    }

    final currency = CurrencyCode.tryParse(params.baseCurrencyCode);
    if (currency == null) {
      return Future.value(
        const FailureResult<Company>(
          ValidationFailure(
            code: CompanyFailureCodes.validationBaseCurrencyInvalid,
          ),
        ),
      );
    }

    if (!CompanyFinancialConfiguration.isValidFractionDigits(
      params.baseCurrencyFractionDigits,
    )) {
      return Future.value(
        const FailureResult<Company>(
          ValidationFailure(
            code:
                CompanyFailureCodes.validationBaseCurrencyFractionDigitsInvalid,
          ),
        ),
      );
    }

    return _repository.update(
      companyId: context.companyId,
      baseCurrencyCode: currency.value,
      baseCurrencyFractionDigits: params.baseCurrencyFractionDigits,
    );
  }
}
