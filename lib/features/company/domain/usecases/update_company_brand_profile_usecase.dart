import '../../../../core/errors/common_failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/company_brand_profile.dart';
import '../entities/current_company_context.dart';
import '../failures/company_branding_failure_codes.dart';
import '../repositories/company_branding_repository.dart';

final class UpdateCompanyBrandProfileParams {
  final CurrentCompanyContext companyContext;
  final DateTime expectedUpdatedAt;
  final String name;
  final String? businessType;
  final String? phone;
  final String? email;
  final String? country;
  final String? city;
  final String? address;
  final String? taxRegistrationNumber;

  const UpdateCompanyBrandProfileParams({
    required this.companyContext,
    required this.expectedUpdatedAt,
    required this.name,
    this.businessType,
    this.phone,
    this.email,
    this.country,
    this.city,
    this.address,
    this.taxRegistrationNumber,
  });
}

final class UpdateCompanyBrandProfileUseCase
    implements UseCase<CompanyBrandProfile, UpdateCompanyBrandProfileParams> {
  final CompanyBrandingRepository _repository;

  const UpdateCompanyBrandProfileUseCase(this._repository);

  @override
  Future<Result<CompanyBrandProfile>> call(
    UpdateCompanyBrandProfileParams params,
  ) {
    if (!params.companyContext.canManageCompany) {
      return Future.value(const FailureResult(
        PermissionFailure(code: CompanyBrandingFailureCodes.permissionDenied),
      ));
    }

    final name = params.name.trim();
    if (name.isEmpty || name.length > 200) {
      return Future.value(const FailureResult(
        ValidationFailure(code: CompanyBrandingFailureCodes.profileInvalid),
      ));
    }

    final normalized = <String?>[
      params.businessType,
      params.phone,
      params.email,
      params.country,
      params.city,
      params.address,
      params.taxRegistrationNumber,
    ].map((value) => value?.trim()).toList();
    const limits = [120, 80, 254, 120, 120, 500, 120];
    for (var index = 0; index < normalized.length; index++) {
      if ((normalized[index]?.length ?? 0) > limits[index]) {
        return Future.value(const FailureResult(
          ValidationFailure(code: CompanyBrandingFailureCodes.profileInvalid),
        ));
      }
    }

    String? valueAt(int index) {
      final value = normalized[index];
      return value == null || value.isEmpty ? null : value;
    }

    return _repository.updateProfile(
      companyId: params.companyContext.companyId,
      expectedUpdatedAt: params.expectedUpdatedAt,
      name: name,
      businessType: valueAt(0),
      phone: valueAt(1),
      email: valueAt(2),
      country: valueAt(3),
      city: valueAt(4),
      address: valueAt(5),
      taxRegistrationNumber: valueAt(6),
    );
  }
}
