import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure_codes.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../entities/payment_method.dart';
import '../policies/payment_methods_permission_policy.dart';
import '../repositories/payment_methods_repository.dart';

class GetActivePaymentMethodsParams {
  final CurrentCompanyContext currentCompanyContext;

  const GetActivePaymentMethodsParams({required this.currentCompanyContext});
}

class GetActivePaymentMethodsUseCase
    implements UseCase<List<PaymentMethod>, GetActivePaymentMethodsParams> {
  final PaymentMethodsRepository _repository;

  const GetActivePaymentMethodsUseCase(this._repository);

  @override
  Future<Result<List<PaymentMethod>>> call(
    GetActivePaymentMethodsParams params,
  ) {
    final context = params.currentCompanyContext;
    if (!PaymentMethodsPermissionPolicy.canViewPaymentMethods(context.role)) {
      return Future.value(
        const FailureResult<List<PaymentMethod>>(
          PermissionFailure(
            code: FailureCodes.permissionPaymentMethodsView,
            message: 'Payment methods view is not allowed.',
          ),
        ),
      );
    }

    return _repository.getActivePaymentMethods(companyId: context.companyId);
  }
}
