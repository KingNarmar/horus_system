import '../../../../core/domain/value_objects/currency_code.dart';
import '../../../../core/errors/common_failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../../../company/domain/failures/company_failure_codes.dart';
import '../entities/customer_statement.dart';
import '../entities/customer_statement_source.dart';
import '../failures/customer_statement_failure_codes.dart';
import '../policies/customer_statements_permission_policy.dart';
import '../repositories/customer_statements_repository.dart';
import '../services/customer_statement_calculator.dart';
import 'customer_statement_params.dart';

final class GetCustomerStatementUseCase
    implements UseCase<CustomerStatement, GetCustomerStatementParams> {
  final CustomerStatementsRepository _repository;
  final CustomerStatementCalculator _calculator;

  const GetCustomerStatementUseCase({
    required CustomerStatementsRepository repository,
    CustomerStatementCalculator calculator = const CustomerStatementCalculator(),
  }) : _repository = repository,
       _calculator = calculator;

  @override
  Future<Result<CustomerStatement>> call(
    GetCustomerStatementParams params,
  ) async {
    final context = params.currentCompanyContext;

    if (!CustomerStatementsPermissionPolicy.canViewStatements(context.role)) {
      return const FailureResult(
        PermissionFailure(
          code: CustomerStatementFailureCodes.permissionView,
        ),
      );
    }

    final customerId = params.customerId.trim();
    if (customerId.isEmpty) {
      return const FailureResult(
        ValidationFailure(
          code: CustomerStatementFailureCodes.validationCustomerIdRequired,
        ),
      );
    }

    final fromDate = _dateOnlyOrNull(params.fromDate);
    final toDate = _dateOnlyOrNull(params.toDate);
    if (fromDate != null && toDate != null && fromDate.isAfter(toDate)) {
      return const FailureResult(
        ValidationFailure(
          code: CustomerStatementFailureCodes.validationDateRange,
        ),
      );
    }

    final company = context.company;
    final currencyCode = company.baseCurrencyCode;
    final fractionDigits = company.baseCurrencyFractionDigits;
    final timezone = company.businessTimezone?.trim();
    final currency = currencyCode == null
        ? null
        : CurrencyCode.tryParse(currencyCode);

    if (currency == null ||
        fractionDigits == null ||
        fractionDigits < 0 ||
        fractionDigits > 4 ||
        timezone == null ||
        timezone.isEmpty) {
      return const FailureResult(
        ConflictFailure(
          code: CompanyFailureCodes.conflictRegionalSettingsNotConfigured,
        ),
      );
    }

    final sourceResult = await _repository.getStatementSource(
      companyId: context.companyId,
      customerId: customerId,
      fromDate: fromDate,
      toDate: toDate,
    );

    return sourceResult.when(
      success: (CustomerStatementSource source) => _calculator.calculate(
        source: source,
        expectedCompanyId: context.companyId,
        expectedCustomerId: customerId,
        expectedCurrency: currency,
        expectedFractionDigits: fractionDigits,
        expectedBusinessTimezone: timezone,
        expectedFromDate: fromDate,
        expectedToDate: toDate,
      ),
      failure: (failure) => FailureResult<CustomerStatement>(failure),
    );
  }

  DateTime? _dateOnlyOrNull(DateTime? value) {
    if (value == null) return null;
    return DateTime(value.year, value.month, value.day);
  }
}
