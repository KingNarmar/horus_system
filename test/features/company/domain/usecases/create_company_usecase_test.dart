import 'package:horus_system/core/domain/value_objects/invoice_prefix.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/entities/company_financial_configuration.dart';
import 'package:horus_system/features/company/domain/failures/company_failure_codes.dart';
import 'package:horus_system/features/company/domain/repositories/company_repository.dart';
import 'package:horus_system/features/company/domain/usecases/create_company_usecase.dart';
import 'package:horus_system/features/company/domain/value_objects/company_timezone.dart';
import 'package:test/test.dart';

void main() {
  group('CreateCompanyUseCase timezone support', () {
    test(
      'normalizes company and timezone values before repository call',
      () async {
        final repository = _FakeCompanyRepository();
        final useCase = CreateCompanyUseCase(repository);

        final result = await useCase(
          const CreateCompanyParams(
            name: '  Horus Transport  ',
            businessTimezone: '  Asia/Dubai  ',
            baseCurrencyCode: ' aed ',
            baseCurrencyFractionDigits: 2,
            invoicePrefix: ' inv ',
            businessType: '  Heavy Transport  ',
          ),
        );

        expect(result.failureOrNull, isNull);
        expect(repository.lastName, 'Horus Transport');
        expect(repository.lastTimezone?.value, 'Asia/Dubai');
        expect(repository.lastBusinessType, 'Heavy Transport');
        expect(
          repository.lastFinancialConfiguration?.baseCurrency.value,
          'AED',
        );
        expect(repository.lastFinancialConfiguration?.fractionDigits, 2);
        expect(repository.lastInvoicePrefix?.value, 'INV');
      },
    );

    test(
      'rejects a missing business timezone before repository access',
      () async {
        final repository = _FakeCompanyRepository();
        final useCase = CreateCompanyUseCase(repository);

        final result = await useCase(
          const CreateCompanyParams(
            name: 'Horus Transport',
            businessTimezone: '   ',
            baseCurrencyCode: 'AED',
            baseCurrencyFractionDigits: 2,
            invoicePrefix: 'INV',
          ),
        );

        expect(
          result.failureOrNull?.code,
          CompanyFailureCodes.validationBusinessTimezoneRequired,
        );
        expect(repository.createCallCount, 0);
      },
    );

    test(
      'rejects a malformed business timezone before repository access',
      () async {
        final repository = _FakeCompanyRepository();
        final useCase = CreateCompanyUseCase(repository);

        final result = await useCase(
          const CreateCompanyParams(
            name: 'Horus Transport',
            businessTimezone: 'Asia /Dubai',
            baseCurrencyCode: 'AED',
            baseCurrencyFractionDigits: 2,
            invoicePrefix: 'INV',
          ),
        );

        expect(
          result.failureOrNull?.code,
          CompanyFailureCodes.validationBusinessTimezoneInvalid,
        );
        expect(repository.createCallCount, 0);
      },
    );
    test('rejects malformed currency before repository access', () async {
      final repository = _FakeCompanyRepository();
      final result = await CreateCompanyUseCase(repository)(
        const CreateCompanyParams(
          name: 'Transport',
          businessTimezone: 'Asia/Dubai',
          baseCurrencyCode: 'EURO',
          baseCurrencyFractionDigits: 2,
          invoicePrefix: 'INV',
        ),
      );
      expect(
        result.failureOrNull?.code,
        CompanyFailureCodes.validationBaseCurrencyInvalid,
      );
      expect(repository.createCallCount, 0);
    });

    test('rejects out of range fraction digits', () async {
      final repository = _FakeCompanyRepository();
      final result = await CreateCompanyUseCase(repository)(
        const CreateCompanyParams(
          name: 'Transport',
          businessTimezone: 'Asia/Dubai',
          baseCurrencyCode: 'AED',
          baseCurrencyFractionDigits: 5,
          invoicePrefix: 'INV',
        ),
      );
      expect(
        result.failureOrNull?.code,
        CompanyFailureCodes.validationBaseCurrencyFractionDigitsInvalid,
      );
      expect(repository.createCallCount, 0);
    });

    test('rejects missing or invalid invoice prefix', () async {
      final repository = _FakeCompanyRepository();
      for (final prefix in ['', '1INV', 'INV!']) {
        final result = await CreateCompanyUseCase(repository)(
          CreateCompanyParams(
            name: 'Transport',
            businessTimezone: 'Asia/Dubai',
            baseCurrencyCode: 'AED',
            baseCurrencyFractionDigits: 2,
            invoicePrefix: prefix,
          ),
        );
        expect(
          result.failureOrNull?.code,
          CompanyFailureCodes.validationInvoicePrefixInvalid,
        );
      }
      expect(repository.createCallCount, 0);
    });
  });
}

final class _FakeCompanyRepository implements CompanyRepository {
  int createCallCount = 0;
  String? lastName;
  CompanyTimezone? lastTimezone;
  String? lastBusinessType;
  CompanyFinancialConfiguration? lastFinancialConfiguration;
  InvoicePrefix? lastInvoicePrefix;

  @override
  Future<Result<Company>> createCompany({
    required String name,
    required CompanyTimezone businessTimezone,
    required CompanyFinancialConfiguration financialConfiguration,
    required InvoicePrefix invoicePrefix,
    String? businessType,
    String? phone,
    String? email,
    String? country,
    String? city,
  }) async {
    createCallCount += 1;
    lastName = name;
    lastTimezone = businessTimezone;
    lastFinancialConfiguration = financialConfiguration;
    lastInvoicePrefix = invoicePrefix;
    lastBusinessType = businessType;
    return Success(
      Company(
        id: 'company-1',
        name: name,
        businessTimezone: businessTimezone.value,
      ),
    );
  }

  @override
  Future<Result<List<Company>>> getMyCompanies() async =>
      const Success<List<Company>>(<Company>[]);
}
