import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure_codes.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../entities/driver_balance.dart';
import '../policies/driver_finance_permission_policy.dart';
import '../repositories/driver_balance_repository.dart';

class GetCanonicalDriverBalanceParams {
  final CurrentCompanyContext currentCompanyContext;
  final String driverId;
  final DateTime beforeExclusive;
  final DateTime? checkpointBeforeExclusive;

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

    final beforeExclusive = _dateOnly(params.beforeExclusive);
    final checkpointBeforeExclusive = params.checkpointBeforeExclusive == null
        ? null
        : _dateOnly(params.checkpointBeforeExclusive!);

    return _repository.getCanonicalDriverBalance(
      companyId: context.companyId,
      driverId: driverId,
      beforeExclusive: beforeExclusive,
      checkpointBeforeExclusive: checkpointBeforeExclusive,
    );
  }

  DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }
}
