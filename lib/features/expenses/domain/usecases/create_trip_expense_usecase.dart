import '../../../../core/domain/services/money_input_parser.dart';
import '../../../../core/domain/value_objects/business_date.dart';
import '../../../../core/errors/common_failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../../../company/domain/entities/company_financial_configuration.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../../../expense_types/domain/entities/expense_type.dart';
import '../../../expense_types/domain/policies/expense_type_semantics.dart';
import '../entities/expense_attribution.dart';
import '../entities/expense_funding_source.dart';
import '../entities/expense_ledger_entry.dart';
import '../failures/expense_ledger_failure_codes.dart';
import 'create_expense_ledger_entry_usecase.dart';

final class CreateTripExpenseParams {
  final CurrentCompanyContext currentCompanyContext;
  final String tripId;
  final ExpenseType expenseType;
  final String amountInput;
  final ExpenseFundingSource fundingSource;
  final BusinessDate expenseDate;
  final String? description;
  final String? notes;

  const CreateTripExpenseParams({
    required this.currentCompanyContext,
    required this.tripId,
    required this.expenseType,
    required this.amountInput,
    required this.fundingSource,
    required this.expenseDate,
    this.description,
    this.notes,
  });
}

final class CreateTripExpenseUseCase
    implements UseCase<ExpenseLedgerEntry, CreateTripExpenseParams> {
  final CreateExpenseLedgerEntryUseCase _createLedgerEntry;
  final MoneyInputParser _moneyInputParser;

  const CreateTripExpenseUseCase(
    this._createLedgerEntry, {
    MoneyInputParser moneyInputParser = const MoneyInputParser(),
  }) : _moneyInputParser = moneyInputParser;

  @override
  Future<Result<ExpenseLedgerEntry>> call(CreateTripExpenseParams params) {
    final context = params.currentCompanyContext;
    final tripId = params.tripId.trim();
    if (tripId.isEmpty) {
      return Future.value(
        const FailureResult<ExpenseLedgerEntry>(
          ValidationFailure(
            code: ExpenseLedgerFailureCodes.validationAttributionInvalid,
          ),
        ),
      );
    }

    final expenseType = params.expenseType;
    if (expenseType.id.trim().isEmpty ||
        expenseType.companyId != context.companyId ||
        !expenseType.isActive ||
        !expenseType.isLedgerEligible ||
        expenseType.code?.trim().isEmpty != false) {
      return Future.value(
        const FailureResult<ExpenseLedgerEntry>(
          ValidationFailure(
            code: ExpenseLedgerFailureCodes.expenseTypeUnavailable,
          ),
        ),
      );
    }

    final submittedDescription = _optional(params.description);
    final requiresDescription = ExpenseTypeSemantics.requiresDescription(
      expenseType,
    );
    if (requiresDescription && submittedDescription == null) {
      return Future.value(
        const FailureResult<ExpenseLedgerEntry>(
          ValidationFailure(
            code: ExpenseLedgerFailureCodes.validationDescriptionRequired,
          ),
        ),
      );
    }
    final description = submittedDescription ?? _optional(expenseType.name);

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

    final amountMinorUnits = _moneyInputParser.tryParseMinorUnits(
      params.amountInput,
      fractionDigits: configuration.fractionDigits,
    );
    if (amountMinorUnits == null || amountMinorUnits <= 0) {
      return Future.value(
        const FailureResult<ExpenseLedgerEntry>(
          ValidationFailure(
            code: ExpenseLedgerFailureCodes.validationAmountInvalid,
          ),
        ),
      );
    }

    return _createLedgerEntry(
      CreateExpenseLedgerEntryParams(
        currentCompanyContext: context,
        expenseTypeId: expenseType.id,
        amountMinorUnits: amountMinorUnits,
        expenseDate: params.expenseDate,
        fundingSource: params.fundingSource,
        attribution: ExpenseAttribution(tripId: tripId),
        description: description,
        notes: _optional(params.notes),
      ),
    );
  }
}

String? _optional(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}
