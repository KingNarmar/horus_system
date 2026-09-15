import '../../../../core/domain/value_objects/business_date.dart';
import '../../../../core/domain/value_objects/money.dart';
import '../../../../core/errors/common_failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../../../company/domain/entities/company_financial_configuration.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../entities/expense_attribution.dart';
import '../entities/expense_funding_source.dart';
import '../entities/expense_ledger_entry.dart';
import '../entities/expense_ledger_write_data.dart';
import '../failures/expense_ledger_failure_codes.dart';
import '../policies/expense_attribution_policy.dart';
import '../policies/expense_ledger_permission_policy.dart';
import '../repositories/expense_ledger_repository.dart';

final class CreateExpenseLedgerEntryParams {
  final CurrentCompanyContext currentCompanyContext;
  final String expenseTypeId;
  final int amountMinorUnits;
  final BusinessDate expenseDate;
  final ExpenseFundingSource fundingSource;
  final ExpenseAttribution attribution;
  final String? referenceNumber;
  final String? notes;

  const CreateExpenseLedgerEntryParams({
    required this.currentCompanyContext,
    required this.expenseTypeId,
    required this.amountMinorUnits,
    required this.expenseDate,
    this.fundingSource = ExpenseFundingSource.company,
    this.attribution = const ExpenseAttribution(),
    this.referenceNumber,
    this.notes,
  });
}

final class CreateExpenseLedgerEntryUseCase
    implements UseCase<ExpenseLedgerEntry, CreateExpenseLedgerEntryParams> {
  final ExpenseLedgerRepository _repository;

  const CreateExpenseLedgerEntryUseCase(this._repository);

  @override
  Future<Result<ExpenseLedgerEntry>> call(
    CreateExpenseLedgerEntryParams params,
  ) {
    final context = params.currentCompanyContext;
    final attribution = params.attribution;

    if (!ExpenseLedgerPermissionPolicy.canManage(
      context.role,
      attribution: attribution,
    )) {
      return Future.value(
        const FailureResult<ExpenseLedgerEntry>(
          PermissionFailure(code: ExpenseLedgerFailureCodes.permissionManage),
        ),
      );
    }

    if (params.expenseTypeId.trim().isEmpty) {
      return Future.value(
        const FailureResult<ExpenseLedgerEntry>(
          ValidationFailure(
            code: ExpenseLedgerFailureCodes.validationExpenseTypeRequired,
          ),
        ),
      );
    }

    if (params.amountMinorUnits <= 0) {
      return Future.value(
        const FailureResult<ExpenseLedgerEntry>(
          ValidationFailure(
            code: ExpenseLedgerFailureCodes.validationAmountInvalid,
          ),
        ),
      );
    }

    if (!ExpenseAttributionPolicy.isAllowed(attribution)) {
      return Future.value(
        const FailureResult<ExpenseLedgerEntry>(
          ValidationFailure(
            code: ExpenseLedgerFailureCodes.validationAttributionInvalid,
          ),
        ),
      );
    }

    final configuration = CompanyFinancialConfiguration.tryCreate(
      baseCurrencyCode: context.company.baseCurrencyCode,
      fractionDigits: context.company.baseCurrencyFractionDigits,
    );
    if (configuration == null) {
      return Future.value(
        const FailureResult<ExpenseLedgerEntry>(
          ValidationFailure(
            code: ExpenseLedgerFailureCodes.financialConfigurationRequired,
          ),
        ),
      );
    }

    return _repository.createEntry(
      ExpenseLedgerWriteData(
        companyId: context.companyId,
        expenseTypeId: params.expenseTypeId.trim(),
        amount: Money(
          minorUnits: params.amountMinorUnits,
          currency: configuration.baseCurrency,
        ),
        currencyFractionDigits: configuration.fractionDigits,
        expenseDate: params.expenseDate,
        fundingSource: params.fundingSource,
        attribution: attribution,
        referenceNumber: params.referenceNumber,
        notes: params.notes,
      ),
    );
  }
}
