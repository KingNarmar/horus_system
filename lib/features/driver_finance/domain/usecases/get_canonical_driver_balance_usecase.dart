import '../../../../core/domain/value_objects/business_date.dart';
import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure_codes.dart';
import '../../../../core/usecases/get_company_business_date_usecase.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../entities/driver_balance.dart';
import '../policies/driver_finance_permission_policy.dart';
import '../repositories/driver_balance_repository.dart';

class GetCanonicalDriverBalanceParams {
  final CurrentCompanyContext currentCompanyContext;
  final String driverId;
  final BusinessDate beforeExclusive;
  final BusinessDate? checkpointBeforeExclusive;

  const GetCanonicalDriverBalanceParams({
    required this.currentCompanyContext,
    required this.driverId,
    required this.beforeExclusive,
    this.checkpointBeforeExclusive,
  });
}

class GetCanonicalDriverBalanceUseCase
    implements UseCase<DriverBalance, GetCanonicalDriverBalanceParams> {
  final DriverBalanceRepository _repository;

  const GetCanonicalDriverBalanceUseCase(this._repository);

  @override
  Future<Result<DriverBalance>> call(GetCanonicalDriverBalanceParams params) {
    final context = params.currentCompanyContext;
    if (!DriverFinancePermissionPolicy.canViewDriverFinance(context.role)) {
      return Future.value(
        const FailureResult<DriverBalance>(
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
        const FailureResult<DriverBalance>(
          ValidationFailure(
            code: FailureCodes.validationDriverIdRequired,
            message: 'Driver id is required.',
          ),
        ),
      );
    }

    return _repository.getCanonicalDriverBalance(
      companyId: context.companyId,
      driverId: driverId,
      beforeExclusive: params.beforeExclusive,
      checkpointBeforeExclusive: params.checkpointBeforeExclusive,
    );
  }
}

class GetCurrentCanonicalDriverBalanceParams {
  final CurrentCompanyContext currentCompanyContext;
  final String driverId;

  const GetCurrentCanonicalDriverBalanceParams({
    required this.currentCompanyContext,
    required this.driverId,
  });
}

class GetCurrentCanonicalDriverBalanceUseCase
    implements UseCase<DriverBalance, GetCurrentCanonicalDriverBalanceParams> {
  final GetCompanyBusinessDateUseCase _getCompanyBusinessDateUseCase;
  final GetCanonicalDriverBalanceUseCase _getCanonicalDriverBalanceUseCase;

  const GetCurrentCanonicalDriverBalanceUseCase({
    required GetCompanyBusinessDateUseCase getCompanyBusinessDateUseCase,
    required GetCanonicalDriverBalanceUseCase getCanonicalDriverBalanceUseCase,
  }) : _getCompanyBusinessDateUseCase = getCompanyBusinessDateUseCase,
       _getCanonicalDriverBalanceUseCase = getCanonicalDriverBalanceUseCase;

  @override
  Future<Result<DriverBalance>> call(
    GetCurrentCanonicalDriverBalanceParams params,
  ) async {
    final businessDateResult = await _getCompanyBusinessDateUseCase(
      GetCompanyBusinessDateParams(
        companyId: params.currentCompanyContext.companyId,
      ),
    );
    if (businessDateResult is FailureResult<BusinessDate>) {
      return FailureResult(businessDateResult.failure);
    }

    final currentBusinessDate =
        (businessDateResult as Success<BusinessDate>).data;
    return _getCanonicalDriverBalanceUseCase(
      GetCanonicalDriverBalanceParams(
        currentCompanyContext: params.currentCompanyContext,
        driverId: params.driverId,
        beforeExclusive: currentBusinessDate.nextDay,
      ),
    );
  }
}
