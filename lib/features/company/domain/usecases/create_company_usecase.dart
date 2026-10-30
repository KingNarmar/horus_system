import 'package:horus_system/core/errors/failure_codes.dart';

import '../../../../core/domain/value_objects/invoice_prefix.dart';
import '../../../../core/domain/value_objects/currency_code.dart';
import '../../../../core/errors/common_failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/company.dart';
import '../entities/company_financial_configuration.dart';
import '../failures/company_failure_codes.dart';
import '../repositories/company_repository.dart';
import '../value_objects/company_timezone.dart';

class CreateCompanyParams {
  final String name;
  final String businessTimezone;
  final String baseCurrencyCode;
  final int baseCurrencyFractionDigits;
  final String invoicePrefix;
  final String? businessType;
  final String? phone;
  final String? email;
  final String? country;
  final String? city;

  const CreateCompanyParams({
    required this.name,
    required this.businessTimezone,
    required this.baseCurrencyCode,
    required this.baseCurrencyFractionDigits,
    required this.invoicePrefix,
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
          ValidationFailure(code: FailureCodes.validationCompanyNameRequired),
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

    final currency = CurrencyCode.tryParse(params.baseCurrencyCode);
    if (currency == null) {
      return Future.value(
        const FailureResult<Company>(
          ValidationFailure(
            code: CompanyFailureCodes.validationBaseCurrencyInvalid,
          ),
        ),
      );
    }

    if (!CompanyFinancialConfiguration.isValidFractionDigits(
      params.baseCurrencyFractionDigits,
    )) {
      return Future.value(
        const FailureResult<Company>(
          ValidationFailure(
            code:
                CompanyFailureCodes.validationBaseCurrencyFractionDigitsInvalid,
          ),
        ),
      );
    }
    final configuration = CompanyFinancialConfiguration(
      baseCurrency: currency,
      fractionDigits: params.baseCurrencyFractionDigits,
    );

    final prefix = InvoicePrefix.tryParse(params.invoicePrefix);
    if (prefix == null) {
      return Future.value(
        const FailureResult<Company>(
          ValidationFailure(
            code: CompanyFailureCodes.validationInvoicePrefixInvalid,
          ),
        ),
      );
    }

    return _repository.createCompany(
      name: companyName,
      businessTimezone: timezone,
      financialConfiguration: configuration,
      invoicePrefix: prefix,
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
