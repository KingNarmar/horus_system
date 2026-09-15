import '../../../../core/domain/value_objects/money.dart';
import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure_codes.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/trip_profit_summary.dart';
import '../failures/trip_failure_codes.dart';

class CalculateTripNetProfitParams {
  final Money? commercialAmount;
  final List<Money> expenses;

  const CalculateTripNetProfitParams({
    required this.commercialAmount,
    required this.expenses,
  });
}

class CalculateTripNetProfitUseCase
    implements UseCase<TripProfitSummary, CalculateTripNetProfitParams> {
  static final BigInt _maxSigned = BigInt.parse('9223372036854775807');
  static final BigInt _minSigned = BigInt.parse('-9223372036854775808');

  const CalculateTripNetProfitUseCase();

  @override
  Future<Result<TripProfitSummary>> call(CalculateTripNetProfitParams params) {
    final commercialAmount = params.commercialAmount;
    if (commercialAmount?.isNegative == true) {
      return Future.value(
        const FailureResult<TripProfitSummary>(
          ValidationFailure(
            code: FailureCodes.validationTripFreightPriceNegative,
            message: 'Trip commercial amount cannot be negative.',
          ),
        ),
      );
    }

    if (commercialAmount == null && params.expenses.isEmpty) {
      return Future.value(const Success(TripProfitSummary()));
    }

    final referenceCurrency =
        commercialAmount?.currency ?? params.expenses.first.currency;
    var expenseMinorUnits = BigInt.zero;

    for (final expense in params.expenses) {
      if (expense.isNegative) {
        return Future.value(
          const FailureResult<TripProfitSummary>(
            ValidationFailure(
              code: FailureCodes.validationTripExpensesNegative,
              message: 'Trip expenses cannot be negative.',
            ),
          ),
        );
      }
      if (expense.currency != referenceCurrency) {
        return Future.value(
          const FailureResult<TripProfitSummary>(
            ValidationFailure(
              code: TripFailureCodes.financialCurrencyMismatch,
              message: 'Trip financial currencies must match.',
            ),
          ),
        );
      }
      expenseMinorUnits += BigInt.from(expense.minorUnits);
    }

    if (!_fitsSignedInt64(expenseMinorUnits)) {
      return Future.value(
        const FailureResult<TripProfitSummary>(
          ValidationFailure(
            code: FailureCodes.validationTripCommercialAmountOverflow,
            message: 'Trip expense total is outside the supported range.',
          ),
        ),
      );
    }

    final totalExpenses = params.expenses.isEmpty
        ? null
        : Money(
            minorUnits: expenseMinorUnits.toInt(),
            currency: referenceCurrency,
          );

    if (commercialAmount == null) {
      return Future.value(
        Success(TripProfitSummary(totalExpenses: totalExpenses)),
      );
    }

    final netMinorUnits =
        BigInt.from(commercialAmount.minorUnits) - expenseMinorUnits;
    if (!_fitsSignedInt64(netMinorUnits)) {
      return Future.value(
        const FailureResult<TripProfitSummary>(
          ValidationFailure(
            code: FailureCodes.validationTripCommercialAmountOverflow,
            message: 'Trip net profit is outside the supported range.',
          ),
        ),
      );
    }

    return Future.value(
      Success(
        TripProfitSummary(
          totalExpenses: totalExpenses,
          netProfit: Money(
            minorUnits: netMinorUnits.toInt(),
            currency: referenceCurrency,
          ),
        ),
      ),
    );
  }

  static bool _fitsSignedInt64(BigInt value) {
    return value >= _minSigned && value <= _maxSigned;
  }
}
