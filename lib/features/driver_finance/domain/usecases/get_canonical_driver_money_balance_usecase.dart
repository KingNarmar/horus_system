import '../../../../core/domain/value_objects/currency_code.dart';
import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure_codes.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../../../company/domain/failures/company_failure_codes.dart';
import '../entities/driver_money_balance.dart';
import '../policies/driver_finance_permission_policy.dart';
import '../repositories/driver_money_balance_repository.dart';
import 'get_canonical_driver_balance_usecase.dart';

final class GetCanonicalDriverMoneyBalanceUseCase
    implements UseCase<DriverMoneyBalance, GetCanonicalDriverBalanceParams> {
  final DriverMoneyBalanceRepository _repository;

  const GetCanonicalDriverMoneyBalanceUseCase(this._repository);

  @override
  Future<Result<DriverMoneyBalance>> call(
    GetCanonicalDriverBalanceParams params,
  ) {
    final context = params.currentCompanyContext;
    if (!DriverFinancePermissionPolicy.canViewDriverFinance(context.role)) {
      return Future.value(
        const FailureResult<DriverMoneyBalance>(
          PermissionFailure(
            code: FailureCodes.permissionDriverFinanceView,
            message: 'Driver finance access is not allowed.',
          ),
        ),
      );
    }

    final driverId = params.driverId.trim();
    if (driverId.isEmpty) {
      return Future.value(
        const FailureResult<DriverMoneyBalance>(
          ValidationFailure(
            code: FailureCodes.validationDriverIdRequired,
            message: 'Driver id is required.',
          ),
        ),
      );
    }

    final rawCurrencyCode = context.company.baseCurrencyCode;
    final fractionDigits = context.company.baseCurrencyFractionDigits;
    if (rawCurrencyCode == null || fractionDigits == null) {
      return Future.value(
        const FailureResult<DriverMoneyBalance>(
          ConflictFailure(
            code: CompanyFailureCodes.conflictFinancialSettingsNotConfigured,
            message: 'Company financial settings are not configured.',
          ),
        ),
      );
    }

    final currency = CurrencyCode.tryParse(rawCurrencyCode);
    if (currency == null) {
      return Future.value(
        const FailureResult<DriverMoneyBalance>(
          ValidationFailure(
            code: CompanyFailureCodes.validationBaseCurrencyInvalid,
            message: 'Company base currency is invalid.',
          ),
        ),
      );
    }

    if (fractionDigits < 0 || fractionDigits > 4) {
      return Future.value(
        const FailureResult<DriverMoneyBalance>(
          ValidationFailure(
            code:
                CompanyFailureCodes.validationBaseCurrencyFractionDigitsInvalid,
            message: 'Company base currency fraction digits are invalid.',
          ),
        ),
      );
    }

    return _repository.getCanonicalDriverMoneyBalance(
      companyId: context.companyId,
      driverId: driverId,
      currency: currency,
      currencyFractionDigits: fractionDigits,
      beforeExclusive: params.beforeExclusive,
      checkpointBeforeExclusive: params.checkpointBeforeExclusive,
    );
  }
}
