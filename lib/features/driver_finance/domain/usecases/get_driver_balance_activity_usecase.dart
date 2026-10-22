import '../../../../core/domain/value_objects/business_date.dart';
import '../../../../core/domain/value_objects/currency_configuration.dart';
import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure_codes.dart';
import '../../../../core/usecases/get_company_business_date_usecase.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../../../company/domain/failures/company_failure_codes.dart';
import '../entities/driver_balance_activity.dart';
import '../policies/driver_finance_permission_policy.dart';
import '../repositories/driver_balance_activity_repository.dart';

final class GetDriverBalanceActivityParams {
  final CurrentCompanyContext currentCompanyContext;
  final String driverId;
  final BusinessDate beforeExclusive;
  final BusinessDate? checkpointBeforeExclusive;

  const GetDriverBalanceActivityParams({
    required this.currentCompanyContext,
    required this.driverId,
    required this.beforeExclusive,
    this.checkpointBeforeExclusive,
  });
}

final class GetDriverBalanceActivityUseCase
    implements UseCase<DriverBalanceActivity, GetDriverBalanceActivityParams> {
  final DriverBalanceActivityRepository _repository;

  const GetDriverBalanceActivityUseCase(this._repository);

  @override
  Future<Result<DriverBalanceActivity>> call(
    GetDriverBalanceActivityParams params,
  ) {
    final context = params.currentCompanyContext;
    if (!DriverFinancePermissionPolicy.canViewDriverFinance(context.role)) {
      return Future.value(
        const FailureResult<DriverBalanceActivity>(
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
        const FailureResult<DriverBalanceActivity>(
          ValidationFailure(
            code: FailureCodes.validationDriverIdRequired,
            message: 'Driver id is required.',
          ),
        ),
      );
    }

    final company = context.company;
    if (company.baseCurrencyCode == null ||
        company.baseCurrencyFractionDigits == null) {
      return Future.value(
        const FailureResult<DriverBalanceActivity>(
          ConflictFailure(
            code: CompanyFailureCodes.conflictFinancialSettingsNotConfigured,
            message: 'Company financial settings are not configured.',
          ),
        ),
      );
    }

    final configuration = CurrencyConfiguration.tryCreate(
      currencyCode: company.baseCurrencyCode,
      fractionDigits: company.baseCurrencyFractionDigits,
    );
    if (configuration == null) {
      final digits = company.baseCurrencyFractionDigits!;
      final invalidDigits =
          digits < CurrencyConfiguration.minFractionDigits ||
          digits > CurrencyConfiguration.maxFractionDigits;
      return Future.value(
        FailureResult<DriverBalanceActivity>(
          ValidationFailure(
            code: invalidDigits
                ? CompanyFailureCodes
                      .validationBaseCurrencyFractionDigitsInvalid
                : CompanyFailureCodes.validationBaseCurrencyInvalid,
            message: 'Invalid company financial currency configuration.',
          ),
        ),
      );
    }

    return _repository.getDriverBalanceActivity(
      companyId: context.companyId,
      driverId: driverId,
      currency: configuration.currency,
      currencyFractionDigits: configuration.fractionDigits,
      beforeExclusive: params.beforeExclusive,
      checkpointBeforeExclusive: params.checkpointBeforeExclusive,
    );
  }
}

final class GetCurrentDriverBalanceActivityParams {
  final CurrentCompanyContext currentCompanyContext;
  final String driverId;

  const GetCurrentDriverBalanceActivityParams({
    required this.currentCompanyContext,
    required this.driverId,
  });
}

/// Uses the trusted company business date, never the device-local date.
final class GetCurrentDriverBalanceActivityUseCase
    implements
        UseCase<DriverBalanceActivity, GetCurrentDriverBalanceActivityParams> {
  final GetCompanyBusinessDateUseCase _getCompanyBusinessDateUseCase;
  final GetDriverBalanceActivityUseCase _getDriverBalanceActivityUseCase;

  const GetCurrentDriverBalanceActivityUseCase({
    required GetCompanyBusinessDateUseCase getCompanyBusinessDateUseCase,
    required GetDriverBalanceActivityUseCase getDriverBalanceActivityUseCase,
  }) : _getCompanyBusinessDateUseCase = getCompanyBusinessDateUseCase,
       _getDriverBalanceActivityUseCase = getDriverBalanceActivityUseCase;

  @override
  Future<Result<DriverBalanceActivity>> call(
    GetCurrentDriverBalanceActivityParams params,
  ) async {
    final context = params.currentCompanyContext;
    // Deny locally before requesting any company-scoped financial activity.
    if (!DriverFinancePermissionPolicy.canViewDriverFinance(context.role)) {
      return const FailureResult(
        PermissionFailure(code: FailureCodes.permissionDriverFinanceView),
      );
    }

    final dateResult = await _getCompanyBusinessDateUseCase(
      GetCompanyBusinessDateParams(companyId: context.companyId),
    );
    if (dateResult is FailureResult<BusinessDate>) {
      return FailureResult(dateResult.failure);
    }

    return _getDriverBalanceActivityUseCase(
      GetDriverBalanceActivityParams(
        currentCompanyContext: context,
        driverId: params.driverId,
        beforeExclusive: (dateResult as Success<BusinessDate>).data.nextDay,
      ),
    );
  }
}
