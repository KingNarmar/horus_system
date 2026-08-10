import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure_codes.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../../../company/domain/entities/company_role.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../entities/payment_method.dart';
import '../entities/payment_method_write_data.dart';
import '../policies/payment_methods_permission_policy.dart';
import '../repositories/payment_methods_repository.dart';

class UpdatePaymentMethodParams {
  final CurrentCompanyContext currentCompanyContext;
  final String paymentMethodId;
  final String name;

  const UpdatePaymentMethodParams({
    required this.currentCompanyContext,
    required this.paymentMethodId,
    required this.name,
  });
}

class UpdatePaymentMethodUseCase
    implements UseCase<PaymentMethod, UpdatePaymentMethodParams> {
  final PaymentMethodsRepository _repository;

  const UpdatePaymentMethodUseCase(this._repository);

  @override
  Future<Result<PaymentMethod>> call(UpdatePaymentMethodParams params) {
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

    final normalizedName = params.name.trim();
    if (normalizedName.isEmpty) {
      return Future.value(
        const FailureResult<PaymentMethod>(
          ValidationFailure(
            code: FailureCodes.validationPaymentMethodNameRequired,
            message: 'Payment method name is required.',
          ),
        ),
      );
    }

    return _repository.updatePaymentMethod(
      paymentMethodId: normalizedId,
      data: PaymentMethodWriteData(
        companyId: context.companyId,
        name: normalizedName,
      ),
      actorRole: context.role.value,
    );
  }
}
