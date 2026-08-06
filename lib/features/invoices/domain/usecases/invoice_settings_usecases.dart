import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure_codes.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../entities/company_invoice_settings.dart';
import '../failures/invoice_failure_codes.dart';
import '../policies/invoices_permission_policy.dart';
import '../repositories/invoice_settings_repository.dart';
import '../value_objects/invoice_prefix.dart';

final class GetInvoiceSettingsParams {
  final CurrentCompanyContext currentCompanyContext;

  const GetInvoiceSettingsParams({required this.currentCompanyContext});
}

final class UpdateInvoiceSettingsParams {
  final CurrentCompanyContext currentCompanyContext;
  final String prefix;

  const UpdateInvoiceSettingsParams({
    required this.currentCompanyContext,
    required this.prefix,
  });
}

final class GetInvoiceSettingsUseCase
    implements UseCase<CompanyInvoiceSettings?, GetInvoiceSettingsParams> {
  final InvoiceSettingsRepository _repository;

  const GetInvoiceSettingsUseCase(this._repository);

  @override
  Future<Result<CompanyInvoiceSettings?>> call(
    GetInvoiceSettingsParams params,
  ) {
    final context = params.currentCompanyContext;
    if (!InvoicesPermissionPolicy.canViewInvoices(context.role)) {
      return Future.value(
        const FailureResult<CompanyInvoiceSettings?>(
          PermissionFailure(code: FailureCodes.permissionInvoicesView),
        ),
      );
    }

    return _repository.get(companyId: context.companyId);
  }
}

final class UpdateInvoiceSettingsUseCase
    implements UseCase<CompanyInvoiceSettings, UpdateInvoiceSettingsParams> {
  final InvoiceSettingsRepository _repository;

  const UpdateInvoiceSettingsUseCase(this._repository);

  @override
  Future<Result<CompanyInvoiceSettings>> call(
    UpdateInvoiceSettingsParams params,
  ) {
    final context = params.currentCompanyContext;
    if (!context.canManageCompany) {
      return Future.value(
        const FailureResult<CompanyInvoiceSettings>(
          PermissionFailure(
            code: InvoiceFailureCodes.permissionSettingsManagement,
          ),
        ),
      );
    }

    final prefix = InvoicePrefix.tryParse(params.prefix);
    if (prefix == null) {
      return Future.value(
        const FailureResult<CompanyInvoiceSettings>(
          ValidationFailure(code: InvoiceFailureCodes.validationPrefixInvalid),
        ),
      );
    }

    return _repository.update(companyId: context.companyId, prefix: prefix);
  }
}
