import '../../../../core/domain/value_objects/currency_code.dart';
import '../../../../core/errors/common_failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/company.dart';
import '../entities/current_company_context.dart';
import '../failures/company_failure_codes.dart';
import '../repositories/company_regional_settings_repository.dart';

final class UpdateCompanyRegionalSettingsParams {
  final CurrentCompanyContext currentCompanyContext;
  final String baseCurrencyCode;
  final int baseCurrencyFractionDigits;
  final String businessTimezone;

  const UpdateCompanyRegionalSettingsParams({
    required this.currentCompanyContext,
    required this.baseCurrencyCode,
    required this.baseCurrencyFractionDigits,
    required this.businessTimezone,
  });
}

final class UpdateCompanyRegionalSettingsUseCase
    implements UseCase<Company, UpdateCompanyRegionalSettingsParams> {
  static const int _minimumFractionDigits = 0;
  static const int _maximumFractionDigits = 4;

  final CompanyRegionalSettingsRepository _repository;

  const UpdateCompanyRegionalSettingsUseCase(this._repository);

  @override
  Future<Result<Company>> call(UpdateCompanyRegionalSettingsParams params) {
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

    final fractionDigits = params.baseCurrencyFractionDigits;
    if (fractionDigits < _minimumFractionDigits ||
        fractionDigits > _maximumFractionDigits) {
      return Future.value(
        const FailureResult<Company>(
          ValidationFailure(
            code:
                CompanyFailureCodes.validationBaseCurrencyFractionDigitsInvalid,
          ),
        ),
      );
    }

    final timezone = params.businessTimezone.trim();
    if (timezone.isEmpty) {
      return Future.value(
        const FailureResult<Company>(
          ValidationFailure(
            code: CompanyFailureCodes.validationBusinessTimezoneRequired,
          ),
        ),
      );
    }

    return _repository.update(
      companyId: context.companyId,
      baseCurrencyCode: currency.value,
      baseCurrencyFractionDigits: fractionDigits,
      businessTimezone: timezone,
    );
  }
}
