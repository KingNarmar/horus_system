import 'package:horus_system/core/errors/failure_codes.dart';
import '../../../../core/errors/common_failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/company.dart';
import '../repositories/company_repository.dart';

class CreateCompanyParams {
  final String name;
  final String? businessType;
  final String? phone;
  final String? email;
  final String? country;
  final String? city;

  const CreateCompanyParams({
    required this.name,
    this.businessType,
    this.phone,
    this.email,
    this.country,
    this.city,
  });
}

class CreateCompanyUseCase implements UseCase<Company, CreateCompanyParams> {
  final CompanyRepository _repository;

  const CreateCompanyUseCase(this._repository);

  @override
  Future<Result<Company>> call(CreateCompanyParams params) {
    final companyName = params.name.trim();

    if (companyName.isEmpty) {
      return Future.value(
        const FailureResult<Company>(
          ValidationFailure(
            code: FailureCodes.validationCompanyNameRequired,
            message: 'Company name is required.',
          ),
        ),
      );
    }

    return _repository.createCompany(
      name: companyName,
      businessType: _normalizeOptionalText(params.businessType),
      phone: _normalizeOptionalText(params.phone),
      email: _normalizeOptionalText(params.email),
      country: _normalizeOptionalText(params.country),
      city: _normalizeOptionalText(params.city),
    );
  }

  String? _normalizeOptionalText(String? value) {
    final normalizedValue = value?.trim();

    if (normalizedValue == null || normalizedValue.isEmpty) {
      return null;
    }

    return normalizedValue;
  }
}
