import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../policies/payment_methods_permission_policy.dart';

class CanManagePaymentMethodsParams {
  final CurrentCompanyContext currentCompanyContext;

  const CanManagePaymentMethodsParams({required this.currentCompanyContext});
}

class CanManagePaymentMethodsUseCase
    implements UseCase<bool, CanManagePaymentMethodsParams> {
  const CanManagePaymentMethodsUseCase();

  @override
  Future<Result<bool>> call(CanManagePaymentMethodsParams params) {
    return Future.value(
      Success<bool>(
        PaymentMethodsPermissionPolicy.canManagePaymentMethods(
          params.currentCompanyContext.role,
        ),
      ),
    );
  }
}
