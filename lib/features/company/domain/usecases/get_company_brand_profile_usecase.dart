import '../../../../core/errors/common_failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/company_brand_profile.dart';
import '../failures/company_branding_failure_codes.dart';
import '../repositories/company_branding_repository.dart';

final class GetCompanyBrandProfileUseCase
    implements UseCase<CompanyBrandProfile, String> {
  final CompanyBrandingRepository _repository;

  const GetCompanyBrandProfileUseCase(this._repository);

  @override
  Future<Result<CompanyBrandProfile>> call(String companyId) {
    if (companyId.trim().isEmpty) {
      return Future.value(const FailureResult(
        ValidationFailure(code: CompanyBrandingFailureCodes.companyUnavailable),
      ));
    }
    return _repository.getProfile(companyId.trim());
  }
}
