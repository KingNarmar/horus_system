import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../policies/payments_permission_policy.dart';

class CanRegisterPaymentsParams {
  final CurrentCompanyContext currentCompanyContext;

  const CanRegisterPaymentsParams({required this.currentCompanyContext});
}

class CanRegisterPaymentsUseCase
    implements UseCase<bool, CanRegisterPaymentsParams> {
  const CanRegisterPaymentsUseCase();

  @override
  Future<Result<bool>> call(CanRegisterPaymentsParams params) {
    return Future.value(
      Success<bool>(
        PaymentsPermissionPolicy.canRegisterPayments(
          params.currentCompanyContext.role,
        ),
      ),
    );
  }
}
