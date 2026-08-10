import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure_codes.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../entities/payment_method.dart';
import '../policies/payment_methods_permission_policy.dart';
import '../repositories/payment_methods_repository.dart';

class DeactivatePaymentMethodParams {
  final CurrentCompanyContext currentCompanyContext;
  final String paymentMethodId;

  const DeactivatePaymentMethodParams({
    required this.currentCompanyContext,
    required this.paymentMethodId,
  });
}

class DeactivatePaymentMethodUseCase
    implements UseCase<PaymentMethod, DeactivatePaymentMethodParams> {
  final PaymentMethodsRepository _repository;

  const DeactivatePaymentMethodUseCase(this._repository);

  @override
  Future<Result<PaymentMethod>> call(DeactivatePaymentMethodParams params) {
    final context = params.currentCompanyContext;
    if (!PaymentMethodsPermissionPolicy.canManagePaymentMethods(context.role)) {
      return Future.value(
        const FailureResult<PaymentMethod>(
          PermissionFailure(
            code: FailureCodes.permissionPaymentMethodsManagement,
            message: 'Payment methods management is not allowed.',
          ),
        ),
      );
    }

    final normalizedId = params.paymentMethodId.trim();
    if (normalizedId.isEmpty) {
      return Future.value(
        const FailureResult<PaymentMethod>(
          ValidationFailure(
            code: FailureCodes.validationPaymentMethodIdRequired,
            message: 'Payment method id is required.',
          ),
        ),
      );
    }

    return _repository.deactivatePaymentMethod(
      companyId: context.companyId,
      paymentMethodId: normalizedId,
      actorRole: context.role.value,
    );
  }
}
