import '../../../../core/errors/common_failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/company.dart';
import '../entities/current_company_context.dart';
import '../failures/company_failure_codes.dart';
import '../repositories/company_timezone_repository.dart';
import '../value_objects/company_timezone.dart';

final class UpdateCompanyBusinessTimezoneParams {
  final CurrentCompanyContext currentCompanyContext;
  final String businessTimezone;

  const UpdateCompanyBusinessTimezoneParams({
    required this.currentCompanyContext,
    required this.businessTimezone,
  });
}

final class UpdateCompanyBusinessTimezoneUseCase
    implements UseCase<Company, UpdateCompanyBusinessTimezoneParams> {
  final CompanyTimezoneRepository _repository;

  const UpdateCompanyBusinessTimezoneUseCase(this._repository);

  @override
  Future<Result<Company>> call(UpdateCompanyBusinessTimezoneParams params) {
    final context = params.currentCompanyContext;
    if (!context.canManageCompany) {
      return Future.value(
        const FailureResult<Company>(
          PermissionFailure(
            code: CompanyFailureCodes.permissionSettingsManagement,
          ),
        ),
      );
    }

    final rawTimezone = params.businessTimezone.trim();
    if (rawTimezone.isEmpty) {
      return Future.value(
        const FailureResult<Company>(
          ValidationFailure(
            code: CompanyFailureCodes.validationBusinessTimezoneRequired,
          ),
        ),
      );
    }

    final timezone = CompanyTimezone.tryParse(rawTimezone);
    if (timezone == null) {
      return Future.value(
        const FailureResult<Company>(
          ValidationFailure(
            code: CompanyFailureCodes.validationBusinessTimezoneInvalid,
          ),
        ),
      );
    }

    return _repository.updateBusinessTimezone(
      companyId: context.companyId,
      businessTimezone: timezone,
    );
  }
}
