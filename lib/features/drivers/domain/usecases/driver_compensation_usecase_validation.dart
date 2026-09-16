import '../../../../core/domain/value_objects/currency_configuration.dart';
import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/errors/failure_codes.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../../../company/domain/failures/company_failure_codes.dart';
import '../failures/driver_compensation_failure_codes.dart';
import '../policies/driver_compensation_permission_policy.dart';

abstract final class DriverCompensationUseCaseValidation {
  static const int maxContractReferenceLength = 200;

  static Failure? validateView(CurrentCompanyContext context) {
    if (context.companyId.trim().isEmpty) {
      return const ValidationFailure(
        code: FailureCodes.validationCompanyIdRequired,
      );
    }
    if (!DriverCompensationPermissionPolicy.canView(context.role)) {
      return const PermissionFailure(
        code: DriverCompensationFailureCodes.permissionView,
      );
    }
    return null;
  }

  static Failure? validateManage(CurrentCompanyContext context) {
    if (context.companyId.trim().isEmpty) {
      return const ValidationFailure(
        code: FailureCodes.validationCompanyIdRequired,
      );
    }
    if (!DriverCompensationPermissionPolicy.canManage(context.role)) {
      return const PermissionFailure(
        code: DriverCompensationFailureCodes.permissionManage,
      );
    }
    return null;
  }

  static Failure? validateDriverId(String driverId) {
    if (driverId.trim().isEmpty) {
      return const ValidationFailure(
        code: FailureCodes.validationDriverIdRequired,
      );
    }
    return null;
  }

  static CurrencyConfiguration? financialConfiguration(
    CurrentCompanyContext context,
  ) {
    return CurrencyConfiguration.tryCreate(
      currencyCode: context.company.baseCurrencyCode,
      fractionDigits: context.company.baseCurrencyFractionDigits,
    );
  }

  static Failure financialConfigurationRequiredFailure() {
    return const ConflictFailure(
      code: CompanyFailureCodes.conflictFinancialSettingsNotConfigured,
    );
  }

  static String? normalizeContractReference(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }
}
