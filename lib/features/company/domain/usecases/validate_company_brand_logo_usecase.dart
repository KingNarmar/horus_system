import '../../../../core/errors/common_failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/company_brand_logo_file.dart';
import '../policies/company_brand_logo_policy.dart';

final class ValidateCompanyBrandLogoUseCase
    implements UseCase<CompanyBrandLogoFile, CompanyBrandLogoFile> {
  const ValidateCompanyBrandLogoUseCase();

  @override
  Future<Result<CompanyBrandLogoFile>> call(CompanyBrandLogoFile file) async {
    final failure = CompanyBrandLogoPolicy.validate(file);
    if (failure != null) {
      return FailureResult(ValidationFailure(code: failure));
    }
    return Success(file);
  }
}
