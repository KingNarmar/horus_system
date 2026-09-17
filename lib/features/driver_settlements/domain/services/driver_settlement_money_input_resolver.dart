import '../../../../core/domain/services/money_decimal_codec.dart';
import '../../../../core/domain/value_objects/currency_configuration.dart';
import '../../../../core/domain/value_objects/money.dart';
import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure_codes.dart';
import '../../../../core/utils/result.dart';
import '../../../company/domain/failures/company_failure_codes.dart';
import '../../../drivers/domain/entities/driver_compensation_revision.dart';
import '../entities/driver_settlement_resolved_money_inputs.dart';
import '../failures/driver_settlement_failure_codes.dart';
import '../usecases/driver_settlement_params.dart';

final class DriverSettlementMoneyInputResolver {
  final MoneyDecimalCodec _moneyCodec;

  const DriverSettlementMoneyInputResolver({
    MoneyDecimalCodec moneyCodec = const MoneyDecimalCodec(),
  }) : _moneyCodec = moneyCodec;

  Result<DriverSettlementResolvedMoneyInputs> resolve({
    required DriverSettlementCalculationParams params,
    required DriverCompensationRevision compensationRevision,
  }) {
    final company = params.currentCompanyContext.company;
    final rawCurrencyCode = company.baseCurrencyCode;
    final fractionDigits = company.baseCurrencyFractionDigits;
    if (rawCurrencyCode == null || fractionDigits == null) {
      return const FailureResult(
        ConflictFailure(
          code: CompanyFailureCodes.conflictFinancialSettingsNotConfigured,
          message: 'Company financial settings are not configured.',
        ),
      );
    }

    if (fractionDigits < CurrencyConfiguration.minFractionDigits ||
        fractionDigits > CurrencyConfiguration.maxFractionDigits) {
      return const FailureResult(
        ValidationFailure(
          code:
              CompanyFailureCodes.validationBaseCurrencyFractionDigitsInvalid,
          message: 'Company base currency fraction digits are invalid.',
        ),
      );
    }

    final configuration = CurrencyConfiguration.tryCreate(
      currencyCode: rawCurrencyCode,
      fractionDigits: fractionDigits,
    );
    if (configuration == null) {
      return const FailureResult(
        ValidationFailure(
          code: CompanyFailureCodes.validationBaseCurrencyInvalid,
          message: 'Company base currency is invalid.',
        ),
      );
    }

    if (compensationRevision.amount.currency != configuration.currency ||
        compensationRevision.currencyFractionDigits !=
            configuration.fractionDigits) {
      return const FailureResult(
        ConflictFailure(
          code: DriverSettlementFailureCodes
              .conflictCompensationCurrencyMismatch,
          message:
              'Driver compensation currency does not match company currency.',
        ),
      );
    }

    final salaryDeductionsResult = _decodeAmount(
      params.salaryDeductionsTotal,
      configuration: configuration,
    );
    final salaryDeductionsFailure = salaryDeductionsResult.failureOrNull;
    if (salaryDeductionsFailure != null) {
      return FailureResult(salaryDeductionsFailure);
    }

    final balanceDeductionResult = _decodeAmount(
      params.balanceDeductionApplied,
      configuration: configuration,
    );
    final balanceDeductionFailure = balanceDeductionResult.failureOrNull;
    if (balanceDeductionFailure != null) {
      return FailureResult(balanceDeductionFailure);
    }

    final settlementDeductionsResult = _decodeAmount(
      params.settlementDeductionsTotal,
      configuration: configuration,
    );
    final settlementDeductionsFailure = settlementDeductionsResult.failureOrNull;
    if (settlementDeductionsFailure != null) {
      return FailureResult(settlementDeductionsFailure);
    }

    final salaryDeductions = salaryDeductionsResult.dataOrNull!;
    final balanceDeduction = balanceDeductionResult.dataOrNull!;
    final settlementDeductions = settlementDeductionsResult.dataOrNull!;
    final netSalary = compensationRevision.amount
        .subtract(balanceDeduction)
        .subtract(salaryDeductions);
    if (netSalary.isNegative) {
      return const FailureResult(
        ValidationFailure(
          code: FailureCodes.validationDriverSettlementNetSalaryNegative,
          message: 'Driver settlement net salary cannot be negative.',
        ),
      );
    }

    return Success(
      DriverSettlementResolvedMoneyInputs(
        currencyConfiguration: configuration,
        grossSalary: compensationRevision.amount,
        salaryDeductionsTotal: salaryDeductions,
        balanceDeductionApplied: balanceDeduction,
        settlementDeductionsTotal: settlementDeductions,
      ),
    );
  }

  Result<Money> _decodeAmount(
    String rawValue, {
    required CurrencyConfiguration configuration,
  }) {
    final normalized = rawValue.trim();
    if (normalized.startsWith('-')) {
      return const FailureResult(
        ValidationFailure(
          code: FailureCodes.validationDriverSettlementAmountNegative,
          message: 'Driver settlement amounts cannot be negative.',
        ),
      );
    }

    final amount = _moneyCodec.tryDecodeNonNegative(
      normalized.isEmpty ? '0' : normalized,
      configuration: configuration,
    );
    if (amount == null) {
      return const FailureResult(
        ValidationFailure(
          code: DriverSettlementFailureCodes.validationAmountInvalid,
          message: 'Driver settlement amount is invalid.',
        ),
      );
    }
    return Success(amount);
  }
}
