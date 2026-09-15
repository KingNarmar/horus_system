import 'package:horus_system/core/domain/value_objects/currency_code.dart';
import 'package:horus_system/core/domain/value_objects/money.dart';
import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/trips/domain/entities/trip_profit_summary.dart';
import 'package:horus_system/features/trips/domain/failures/trip_failure_codes.dart';
import 'package:horus_system/features/trips/domain/usecases/trips_usecases.dart';
import 'package:test/test.dart';

void main() {
  final aed = CurrencyCode.tryParse('AED')!;
  final usd = CurrencyCode.tryParse('USD')!;
  const useCase = CalculateTripNetProfitUseCase();

  Money aedMoney(int minorUnits) => Money(minorUnits: minorUnits, currency: aed);

  group('CalculateTripNetProfitUseCase', () {
    test('subtracts canonical expense Money from commercial snapshot', () async {
      final result = await useCase(
        CalculateTripNetProfitParams(
          commercialAmount: aedMoney(300000),
          expenses: [aedMoney(125000), aedMoney(80000)],
        ),
      );

      expect(result, isA<Success<TripProfitSummary>>());
      expect(result.dataOrNull?.totalExpenses, aedMoney(205000));
      expect(result.dataOrNull?.netProfit, aedMoney(95000));
    });

    test('returns no financial projection when all inputs are absent', () async {
      final result = await useCase(
        const CalculateTripNetProfitParams(
          commercialAmount: null,
          expenses: [],
        ),
      );

      expect(result, isA<Success<TripProfitSummary>>());
      expect(result.dataOrNull?.totalExpenses, isNull);
      expect(result.dataOrNull?.netProfit, isNull);
    });

    test('keeps expense total when legacy trip has no commercial amount', () async {
      final result = await useCase(
        CalculateTripNetProfitParams(
          commercialAmount: null,
          expenses: [aedMoney(30000)],
        ),
      );

      expect(result, isA<Success<TripProfitSummary>>());
      expect(result.dataOrNull?.totalExpenses, aedMoney(30000));
      expect(result.dataOrNull?.netProfit, isNull);
    });

    test('rejects negative commercial amount', () async {
      final result = await useCase(
        CalculateTripNetProfitParams(
          commercialAmount: aedMoney(-1),
          expenses: const [],
        ),
      );

      expect(result, isA<FailureResult<TripProfitSummary>>());
      expect(
        result.failureOrNull?.code,
        FailureCodes.validationTripFreightPriceNegative,
      );
    });

    test('rejects negative expense amount', () async {
      final result = await useCase(
        CalculateTripNetProfitParams(
          commercialAmount: aedMoney(10000),
          expenses: [aedMoney(-1)],
        ),
      );

      expect(result, isA<FailureResult<TripProfitSummary>>());
      expect(
        result.failureOrNull?.code,
        FailureCodes.validationTripExpensesNegative,
      );
    });

    test('rejects mixed financial currencies', () async {
      final result = await useCase(
        CalculateTripNetProfitParams(
          commercialAmount: aedMoney(10000),
          expenses: [Money(minorUnits: 100, currency: usd)],
        ),
      );

      expect(result, isA<FailureResult<TripProfitSummary>>());
      expect(
        result.failureOrNull?.code,
        TripFailureCodes.financialCurrencyMismatch,
      );
    });

    test('rejects signed-int64 overflow while summing expenses', () async {
      final result = await useCase(
        CalculateTripNetProfitParams(
          commercialAmount: null,
          expenses: [
            aedMoney(9223372036854775807),
            aedMoney(1),
          ],
        ),
      );

      expect(result, isA<FailureResult<TripProfitSummary>>());
      expect(
        result.failureOrNull?.code,
        FailureCodes.validationTripCommercialAmountOverflow,
      );
    });
  });
}
