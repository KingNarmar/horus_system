import 'package:test/test.dart';
import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/trips/domain/usecases/trips_usecases.dart';

void main() {
  group('CalculateTripNetProfitUseCase', () {
    const useCase = CalculateTripNetProfitUseCase();

    test('returns freight price minus total expenses', () async {
      final result = await useCase(
        const CalculateTripNetProfitParams(
          freightPrice: 3000,
          totalExpenses: 2050,
        ),
      );

      expect(result, isA<Success<double>>());
      expect(result.dataOrNull, 950);
    });

    test('treats missing total expenses as zero', () async {
      final result = await useCase(
        const CalculateTripNetProfitParams(
          freightPrice: 1200,
          totalExpenses: null,
        ),
      );

      expect(result, isA<Success<double>>());
      expect(result.dataOrNull, 1200);
    });

    test('treats missing freight price as zero', () async {
      final result = await useCase(
        const CalculateTripNetProfitParams(
          freightPrice: null,
          totalExpenses: 300,
        ),
      );

      expect(result, isA<Success<double>>());
      expect(result.dataOrNull, -300);
    });

    test('rejects negative freight price', () async {
      final result = await useCase(
        const CalculateTripNetProfitParams(freightPrice: -1, totalExpenses: 0),
      );

      expect(result, isA<FailureResult<double>>());
      expect(
        result.failureOrNull?.code,
        FailureCodes.validationTripFreightPriceNegative,
      );
    });

    test('rejects negative total expenses', () async {
      final result = await useCase(
        const CalculateTripNetProfitParams(
          freightPrice: 100,
          totalExpenses: -1,
        ),
      );

      expect(result, isA<FailureResult<double>>());
      expect(
        result.failureOrNull?.code,
        FailureCodes.validationTripExpensesNegative,
      );
    });
  });
}
