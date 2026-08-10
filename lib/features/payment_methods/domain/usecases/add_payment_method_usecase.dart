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

class AddPaymentMethodParams {
  final CurrentCompanyContext currentCompanyContext;
  final String name;

  const AddPaymentMethodParams({
    required this.currentCompanyContext,
    required this.name,
  });
}

class AddPaymentMethodUseCase
    implements UseCase<PaymentMethod, AddPaymentMethodParams> {
  final PaymentMethodsRepository _repository;

  const AddPaymentMethodUseCase(this._repository);

  @override
  Future<Result<PaymentMethod>> call(AddPaymentMethodParams params) {
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

    return _repository.addPaymentMethod(
      data: PaymentMethodWriteData(
        companyId: context.companyId,
        name: normalizedName,
      ),
      actorRole: context.role.value,
    );
  }
}
