import '../../../../core/errors/common_failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/company_brand_profile.dart';
import '../entities/current_company_context.dart';
import '../failures/company_branding_failure_codes.dart';
import '../repositories/company_branding_repository.dart';

final class RemoveCompanyBrandLogoParams {
  final CurrentCompanyContext companyContext;
  final String? expectedLogoPath;

  const RemoveCompanyBrandLogoParams({
    required this.companyContext,
    required this.expectedLogoPath,
  });
}

final class RemoveCompanyBrandLogoUseCase
    implements UseCase<CompanyBrandProfile, RemoveCompanyBrandLogoParams> {
  final CompanyBrandingRepository _repository;

  const RemoveCompanyBrandLogoUseCase(this._repository);

  @override
  Future<Result<CompanyBrandProfile>> call(RemoveCompanyBrandLogoParams params) {
    if (!params.companyContext.canManageCompany) {
      return Future.value(const FailureResult(
        PermissionFailure(code: CompanyBrandingFailureCodes.permissionDenied),
      ));
    }
    return _repository.removeLogo(
      companyId: params.companyContext.companyId,
      expectedLogoPath: params.expectedLogoPath,
    );
  }
}
