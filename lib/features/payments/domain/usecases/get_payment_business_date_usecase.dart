import '../../../../core/domain/services/company_business_date_provider.dart';
import '../../../../core/domain/value_objects/currency_code.dart';
import '../../../../core/errors/common_failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../../../company/domain/failures/company_failure_codes.dart';
import '../failures/payment_failure_codes.dart';
import '../policies/payments_permission_policy.dart';
import 'payment_params.dart';

final class GetPaymentBusinessDateUseCase
    implements UseCase<DateTime, GetPaymentBusinessDateParams> {
  final CompanyBusinessDateProvider _businessDateProvider;

  const GetPaymentBusinessDateUseCase(this._businessDateProvider);

  @override
  Future<Result<DateTime>> call(GetPaymentBusinessDateParams params) {
    final context = params.currentCompanyContext;
    if (!PaymentsPermissionPolicy.canRegisterPayments(context.role)) {
      return Future.value(
        const FailureResult<DateTime>(
          PermissionFailure(code: PaymentFailureCodes.permissionManage),
        ),
      );
    }

    final fractionDigits = context.company.baseCurrencyFractionDigits;
    final currency = CurrencyCode.tryParse(
      context.company.baseCurrencyCode ?? '',
    );
    if (currency == null ||
        fractionDigits == null ||
        fractionDigits < 0 ||
        fractionDigits > 4) {
      return Future.value(
        const FailureResult<DateTime>(
          ConflictFailure(
            code: CompanyFailureCodes.conflictRegionalSettingsNotConfigured,
          ),
        ),
      );
    }

    return _businessDateProvider.getBusinessDate(companyId: context.companyId);
  }
}
