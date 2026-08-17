import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure_codes.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import 'trip_usecase_params.dart';

class CalculateTripNetProfitUseCase
    implements UseCase<double, CalculateTripNetProfitParams> {
  const CalculateTripNetProfitUseCase();

  @override
  Future<Result<double>> call(CalculateTripNetProfitParams params) {
    final freightPrice = params.freightPrice ?? 0;
    final totalExpenses = params.totalExpenses ?? 0;

    if (freightPrice < 0) {
      return Future.value(
        const FailureResult<double>(
          ValidationFailure(
            code: FailureCodes.validationTripFreightPriceNegative,
            message: 'Freight price cannot be negative.',
          ),
        ),
      );
    }

    if (totalExpenses < 0) {
      return Future.value(
        const FailureResult<double>(
          ValidationFailure(
            code: FailureCodes.validationTripExpensesNegative,
            message: 'Trip expenses cannot be negative.',
          ),
        ),
      );
    }

    return Future.value(Success<double>(freightPrice - totalExpenses));
  }
}
