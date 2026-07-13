import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/driver_finance/domain/entities/driver_balance.dart';
import 'package:horus_system/features/driver_finance/domain/entities/driver_financial_movement.dart';
import 'package:horus_system/features/driver_finance/domain/entities/driver_financial_movement_type.dart';
import 'package:horus_system/features/driver_finance/domain/usecases/driver_finance_usecases.dart';
import 'package:test/test.dart';

void main() {
  group('CalculateDriverBalanceUseCase driver-perspective contract', () {
    const useCase = CalculateDriverBalanceUseCase();

    test('advance received makes the driver owe the company', () async {
      final result = await useCase(
        CalculateDriverBalanceParams(
          companyId: _companyId,
          driverId: _driverId,
          movements: [
            _movement(
              id: 'advance-1',
              type: DriverFinancialMovementType.advance,
              amount: 7000,
            ),
          ],
        ),
      );

      expect(result, isA<Success<DriverBalance>>());
      expect(result.dataOrNull?.totalAdvances, 7000);
      expect(result.dataOrNull?.totalDriverCharges, 0);
      expect(result.dataOrNull?.totalCashReturns, 0);
      expect(result.dataOrNull?.netBalance, -7000);
    });

    test('driver charge is an amount owed by the driver', () async {
      final result = await useCase(
        CalculateDriverBalanceParams(
          companyId: _companyId,
          driverId: _driverId,
          movements: [
            _movement(
              id: 'charge-1',
              type: DriverFinancialMovementType.driverCharge,
              amount: 500,
            ),
          ],
        ),
      );

      expect(result, isA<Success<DriverBalance>>());
      expect(result.dataOrNull?.totalAdvances, 0);
      expect(result.dataOrNull?.totalDriverCharges, 500);
      expect(result.dataOrNull?.totalCashReturns, 0);
      expect(result.dataOrNull?.netBalance, -500);
    });

    test('advance and driver charge accumulate as driver debt', () async {
      final result = await useCase(
        CalculateDriverBalanceParams(
          companyId: _companyId,
          driverId: _driverId,
          movements: [
            _movement(
              id: 'advance-1',
              type: DriverFinancialMovementType.advance,
              amount: 7000,
            ),
            _movement(
              id: 'charge-1',
              type: DriverFinancialMovementType.driverCharge,
              amount: 500,
            ),
          ],
        ),
      );

      expect(result, isA<Success<DriverBalance>>());
      expect(result.dataOrNull?.netBalance, -7500);
    });

    test('cash return reduces the amount owed by the driver', () async {
      final result = await useCase(
        CalculateDriverBalanceParams(
          companyId: _companyId,
          driverId: _driverId,
          movements: [
            _movement(
              id: 'advance-1',
              type: DriverFinancialMovementType.advance,
              amount: 7000,
            ),
            _movement(
              id: 'cash-return-1',
              type: DriverFinancialMovementType.cashReturn,
              amount: 2000,
            ),
          ],
        ),
      );

      expect(result, isA<Success<DriverBalance>>());
      expect(result.dataOrNull?.totalCashReturns, 2000);
      expect(result.dataOrNull?.netBalance, -5000);
    });

    test('empty movements produce a settled balance', () async {
      final result = await useCase(
        const CalculateDriverBalanceParams(
          companyId: _companyId,
          driverId: _driverId,
          movements: [],
        ),
      );

      expect(result, isA<Success<DriverBalance>>());
      expect(result.dataOrNull?.netBalance, 0);
    });
  });
}

const _companyId = 'company-1';
const _driverId = 'driver-1';

DriverFinancialMovement _movement({
  required String id,
  required DriverFinancialMovementType type,
  required double amount,
}) {
  return DriverFinancialMovement(
    id: id,
    companyId: _companyId,
    driverId: _driverId,
    type: type,
    amount: amount,
    movementDate: DateTime(2026, 7, 1),
  );
}
