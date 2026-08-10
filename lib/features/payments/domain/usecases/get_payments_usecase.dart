import '../../../../core/errors/common_failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/payment.dart';
import '../failures/payment_failure_codes.dart';
import '../policies/payments_permission_policy.dart';
import '../repositories/payments_repository.dart';
import 'payment_params.dart';

final class GetPaymentsUseCase
    implements UseCase<List<Payment>, GetPaymentsParams> {
  final PaymentsRepository _repository;

  const GetPaymentsUseCase(this._repository);

  @override
  Future<Result<List<Payment>>> call(GetPaymentsParams params) {
    final context = params.currentCompanyContext;
    if (!PaymentsPermissionPolicy.canViewPayments(context.role)) {
      return Future.value(
        const FailureResult<List<Payment>>(
          PermissionFailure(code: PaymentFailureCodes.permissionView),
        ),
      );
    }

    return _repository.getPayments(companyId: context.companyId);
  }
}
