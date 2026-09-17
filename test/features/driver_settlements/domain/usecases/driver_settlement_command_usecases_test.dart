import 'package:horus_system/core/domain/value_objects/currency_code.dart';
import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/driver_settlements/domain/usecases/driver_settlement_usecases.dart';
import 'package:test/test.dart';

import 'driver_settlement_usecases_test_support.dart';

void main() {
  group('Driver settlement existing commands', () {
    test('loads company-scoped driver options for finance roles', () async {
      final repository = FakeDriverSettlementsRepository();
      final useCase = GetDriverSettlementDriverOptionsUseCase(repository);

      final result = await useCase(
        GetDriverSettlementDriverOptionsParams(
          currentCompanyContext: settlementTestContext(CompanyRole.accountant),
        ),
      );

      expect(result, isA<Success>());
      expect(result.dataOrNull, hasLength(1));
      expect(repository.driverOptionsCalls, 1);
    });

    test('rejects invalid settlement periods before repository access', () async {
      final currency = CurrencyCode.tryParse('AED')!;
      final legacyRepository = FakeDriverSettlementsRepository();
      final moneyRepository = FakeSettlementMoneyRepository(
        snapshot: settlementTestMoneySnapshot(currency: currency),
      );
      final compensationRepository = FakeCompensationRepository([
        settlementTestRevision(currency: currency, amountMinorUnits: 100000),
      ]);
      final balanceRepository = FakeMoneyBalanceRepository(
        settlementTestMoneyBalance(currency: currency),
      );
      final useCase = CalculateDriverSettlementPreviewUseCase(
        createSettlementResolver(
          legacyRepository: legacyRepository,
          moneyRepository: moneyRepository,
          compensationRepository: compensationRepository,
          balanceRepository: balanceRepository,
        ),
      );

      final result = await useCase(
        DriverSettlementCalculationParams(
          currentCompanyContext: settlementTestContext(CompanyRole.accountant),
          driverId: testDriverId,
          periodStart: settlementTestDate(2026, 8, 1),
          periodEnd: settlementTestDate(2026, 7, 1),
        ),
      );

      expect(result, isA<FailureResult>());
      expect(
        result.failureOrNull?.code,
        FailureCodes.validationDriverSettlementPeriodInvalid,
      );
      expect(legacyRepository.driverOptionCalls, 0);
      expect(compensationRepository.historyCalls, 0);
    });

    test('requires a void reason', () async {
      final repository = FakeDriverSettlementsRepository();
      final useCase = VoidDriverSettlementUseCase(repository);

      final result = await useCase(
        VoidDriverSettlementParams(
          currentCompanyContext: settlementTestContext(CompanyRole.admin),
          settlementId: 'settlement-1',
          reason: '  ',
        ),
      );

      expect(result, isA<FailureResult>());
      expect(
        result.failureOrNull?.code,
        FailureCodes.validationDriverSettlementVoidReasonRequired,
      );
      expect(repository.voidCalls, 0);
    });
  });
}
