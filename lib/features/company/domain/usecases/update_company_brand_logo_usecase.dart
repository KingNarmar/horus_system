import '../../../../core/errors/common_failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/company_brand_logo_file.dart';
import '../entities/company_brand_profile.dart';
import '../entities/current_company_context.dart';
import '../failures/company_branding_failure_codes.dart';
import '../policies/company_brand_logo_policy.dart';
import '../repositories/company_branding_repository.dart';

final class UpdateCompanyBrandLogoParams {
  final CurrentCompanyContext companyContext;
  final String? expectedLogoPath;
  final CompanyBrandLogoFile logo;

  const UpdateCompanyBrandLogoParams({
    required this.companyContext,
    required this.expectedLogoPath,
    required this.logo,
  });
}

final class UpdateCompanyBrandLogoUseCase
    implements UseCase<CompanyBrandProfile, UpdateCompanyBrandLogoParams> {
  final CompanyBrandingRepository _repository;

  const UpdateCompanyBrandLogoUseCase(this._repository);

  @override
  Future<Result<CompanyBrandProfile>> call(UpdateCompanyBrandLogoParams params) {
    if (!params.companyContext.canManageCompany) {
      return Future.value(const FailureResult(
        PermissionFailure(code: CompanyBrandingFailureCodes.permissionDenied),
      ));
    }
    final code = CompanyBrandLogoPolicy.validate(params.logo);
    if (code != null) {
      return Future.value(FailureResult(ValidationFailure(code: code)));
    }
    return _repository.updateLogo(
      companyId: params.companyContext.companyId,
      expectedLogoPath: params.expectedLogoPath,
      logo: params.logo,
    );
  }
}
