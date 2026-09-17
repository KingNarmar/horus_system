import 'package:horus_system/core/domain/value_objects/currency_code.dart';
import 'package:horus_system/core/domain/value_objects/money.dart';
import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/driver_settlements/domain/entities/driver_settlement.dart';
import 'package:horus_system/features/driver_settlements/domain/entities/driver_settlement_driver_option.dart';
import 'package:horus_system/features/driver_settlements/domain/entities/driver_settlement_item_direction.dart';
import 'package:horus_system/features/driver_settlements/domain/entities/driver_settlement_item_source_type.dart';
import 'package:horus_system/features/driver_settlements/domain/entities/driver_settlement_money_item.dart';
import 'package:horus_system/features/driver_settlements/domain/failures/driver_settlement_failure_codes.dart';
import 'package:horus_system/features/driver_settlements/domain/usecases/driver_settlement_usecases.dart';
import 'package:horus_system/features/drivers/domain/failures/driver_compensation_failure_codes.dart';
import 'package:test/test.dart';

import 'driver_settlement_usecases_test_support.dart';

void main() {
  group('Driver settlement PC-09 orchestration', () {
    test('auto-resolves compensation and canonical exact sources', () async {
      final currency = CurrencyCode.tryParse('AED')!;
      final legacyRepository = FakeDriverSettlementsRepository();
      final moneyRepository = FakeSettlementMoneyRepository(
        snapshot: settlementTestMoneySnapshot(
          currency: currency,
          advances: 30000,
          tripExpenses: 10000,
          returnedCash: 5000,
          deductions: 2500,
          items: [
            DriverSettlementMoneyItem(
              companyId: testCompanyId,
              sourceType:
                  DriverSettlementItemSourceType.driverFinancialMovement,
              sourceId: 'movement-1',
              direction: DriverSettlementItemDirection.driverToCompany,
              amount: Money(minorUnits: 30000, currency: currency),
              labelKey: 'driver_settlement_item_advance',
            ),
          ],
        ),
      );
      final compensationRepository = FakeCompensationRepository([
        settlementTestRevision(currency: currency, amountMinorUnits: 100000),
      ]);
      final balanceRepository = FakeMoneyBalanceRepository(
        settlementTestMoneyBalance(
          currency: currency,
          openingMinorUnits: -10000,
        ),
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
          currentCompanyContext: settlementTestContext(CompanyRole.owner),
          driverId: testDriverId,
          periodStart: settlementTestDate(2026, 7, 1),
          periodEnd: settlementTestDate(2026, 7, 31),
          salaryDeductionsTotal: '100.00',
          balanceDeductionApplied: '50.00',
          settlementDeductionsTotal: '25.00',
        ),
      );

      expect(result, isA<Success>());
      final preview = result.dataOrNull!;
      expect(preview.compensationRevisionId, 'revision-1');
      expect(preview.currencyFractionDigits, 2);
      expect(preview.calculation.grossSalary.minorUnits, 100000);
      expect(preview.calculation.netSalaryPayable.minorUnits, 85000);
      expect(preview.calculation.openingDriverBalance.minorUnits, -10000);
      expect(preview.calculation.closingDriverBalance.minorUnits, -25000);
      expect(preview.items, hasLength(2));
      expect(compensationRepository.historyCalls, 1);
      expect(balanceRepository.calls, 1);
      expect(
        balanceRepository.lastBeforeExclusive,
        settlementTestDate(2026, 7, 1),
      );
      expect(
        balanceRepository.lastCheckpointBeforeExclusive,
        settlementTestDate(2026, 7, 1),
      );
      expect(moneyRepository.snapshotCalls, 1);
    });

    test('itemizes manual settlement deduction exactly once', () async {
      final currency = CurrencyCode.tryParse('AED')!;
      final legacyRepository = FakeDriverSettlementsRepository();
      final moneyRepository = FakeSettlementMoneyRepository(
        snapshot: settlementTestMoneySnapshot(currency: currency),
      );
      final compensationRepository = FakeCompensationRepository([
        settlementTestRevision(currency: currency, amountMinorUnits: 100000),
      ]);
      final balanceRepository = FakeMoneyBalanceRepository(
        settlementTestMoneyBalance(
          currency: currency,
          openingMinorUnits: -5000,
        ),
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
          periodStart: settlementTestDate(2026, 7, 1),
          periodEnd: settlementTestDate(2026, 7, 31),
          settlementDeductionsTotal: '12.50',
        ),
      );

      expect(result, isA<Success>());
      final preview = result.dataOrNull!;
      expect(preview.items, hasLength(1));
      final item = preview.items.single;
      expect(item.sourceType, DriverSettlementItemSourceType.manualAdjustment);
      expect(item.direction, DriverSettlementItemDirection.driverToCompany);
      expect(item.amount.minorUnits, 1250);
      expect(item.sourceDate, settlementTestDate(2026, 7, 31));
      expect(item.metadata['adjustment_kind'], 'settlement_deduction');
      expect(preview.calculation.settlementDeductionsTotal.minorUnits, 1250);
      expect(preview.calculation.closingDriverBalance.minorUnits, -6250);
    });

    test('supports three-decimal settlement input exactly', () async {
      final currency = CurrencyCode.tryParse('KWD')!;
      final legacyRepository = FakeDriverSettlementsRepository();
      final moneyRepository = FakeSettlementMoneyRepository(
        snapshot: settlementTestMoneySnapshot(currency: currency),
      );
      final compensationRepository = FakeCompensationRepository([
        settlementTestRevision(
          currency: currency,
          fractionDigits: 3,
          amountMinorUnits: 123456,
        ),
      ]);
      final balanceRepository = FakeMoneyBalanceRepository(
        settlementTestMoneyBalance(
          currency: currency,
          fractionDigits: 3,
        ),
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
          currentCompanyContext: settlementTestContext(
            CompanyRole.accountant,
            currencyCode: 'KWD',
            fractionDigits: 3,
          ),
          driverId: testDriverId,
          periodStart: settlementTestDate(2026, 7, 1),
          periodEnd: settlementTestDate(2026, 7, 31),
          salaryDeductionsTotal: '0.456',
        ),
      );

      expect(result, isA<Success>());
      expect(result.dataOrNull!.calculation.grossSalary.minorUnits, 123456);
      expect(
        result.dataOrNull!.calculation.salaryDeductionsTotal.minorUnits,
        456,
      );
      expect(result.dataOrNull!.calculation.netSalaryPayable.minorUnits, 123000);
    });

    test('rejects over-precision before loading financial sources', () async {
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
          periodStart: settlementTestDate(2026, 7, 1),
          periodEnd: settlementTestDate(2026, 7, 31),
          salaryDeductionsTotal: '0.001',
        ),
      );

      expect(result, isA<FailureResult>());
      expect(
        result.failureOrNull?.code,
        DriverSettlementFailureCodes.validationAmountInvalid,
      );
      expect(balanceRepository.calls, 0);
      expect(moneyRepository.snapshotCalls, 0);
    });

    test('requires one compensation revision to cover the full period', () async {
      final currency = CurrencyCode.tryParse('AED')!;
      final legacyRepository = FakeDriverSettlementsRepository();
      final moneyRepository = FakeSettlementMoneyRepository(
        snapshot: settlementTestMoneySnapshot(currency: currency),
      );
      final compensationRepository = FakeCompensationRepository([
        settlementTestRevision(
          id: 'old',
          currency: currency,
          amountMinorUnits: 100000,
          effectiveFrom: settlementTestDate(2026, 7, 1),
          effectiveTo: settlementTestDate(2026, 7, 15),
        ),
        settlementTestRevision(
          id: 'new',
          currency: currency,
          amountMinorUnits: 110000,
          effectiveFrom: settlementTestDate(2026, 7, 16),
        ),
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
          periodStart: settlementTestDate(2026, 7, 1),
          periodEnd: settlementTestDate(2026, 7, 31),
        ),
      );

      expect(result, isA<FailureResult>());
      expect(
        result.failureOrNull?.code,
        DriverCompensationFailureCodes.notFoundForPeriod,
      );
      expect(balanceRepository.calls, 0);
      expect(moneyRepository.snapshotCalls, 0);
    });

    test('rejects recovery above exact outstanding driver debt', () async {
      final currency = CurrencyCode.tryParse('AED')!;
      final legacyRepository = FakeDriverSettlementsRepository();
      final moneyRepository = FakeSettlementMoneyRepository(
        snapshot: settlementTestMoneySnapshot(currency: currency),
      );
      final compensationRepository = FakeCompensationRepository([
        settlementTestRevision(currency: currency, amountMinorUnits: 50000),
      ]);
      final balanceRepository = FakeMoneyBalanceRepository(
        settlementTestMoneyBalance(
          currency: currency,
          openingMinorUnits: -10000,
        ),
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
          periodStart: settlementTestDate(2026, 7, 1),
          periodEnd: settlementTestDate(2026, 7, 31),
          balanceDeductionApplied: '150.00',
        ),
      );

      expect(result, isA<FailureResult>());
      expect(
        result.failureOrNull?.code,
        FailureCodes.validationDriverSettlementBalanceRecoveryExceedsDebt,
      );
      expect(moneyRepository.createDraftCalls, 0);
    });

    test('draft snapshots resolved compensation and exact currency data', () async {
      final currency = CurrencyCode.tryParse('AED')!;
      final legacyRepository = FakeDriverSettlementsRepository();
      final moneyRepository = FakeSettlementMoneyRepository(
        snapshot: settlementTestMoneySnapshot(
          currency: currency,
          advances: 2500,
        ),
      );
      final compensationRepository = FakeCompensationRepository([
        settlementTestRevision(currency: currency, amountMinorUnits: 100000),
      ]);
      final balanceRepository = FakeMoneyBalanceRepository(
        settlementTestMoneyBalance(
          currency: currency,
          openingMinorUnits: -5000,
        ),
      );
      final resolver = createSettlementResolver(
        legacyRepository: legacyRepository,
        moneyRepository: moneyRepository,
        compensationRepository: compensationRepository,
        balanceRepository: balanceRepository,
      );
      final useCase = CreateDriverSettlementDraftUseCase(
        moneyRepository: moneyRepository,
        resolveCalculation: resolver,
      );

      final result = await useCase(
        CreateDriverSettlementDraftParams(
          currentCompanyContext: settlementTestContext(CompanyRole.accountant),
          driverId: testDriverId,
          periodStart: settlementTestDate(2026, 7, 1),
          periodEnd: settlementTestDate(2026, 7, 31),
          salaryDeductionsTotal: '10.00',
          settlementDeductionsTotal: '12.50',
          notes: 'snapshot',
        ),
      );

      expect(result, isA<Success<DriverSettlement>>());
      expect(moneyRepository.createDraftCalls, 1);
      final write = moneyRepository.lastWriteData!;
      expect(write.compensationRevisionId, 'revision-1');
      expect(write.currencyFractionDigits, 2);
      expect(write.calculation.grossSalary.minorUnits, 100000);
      expect(write.calculation.openingDriverBalance.minorUnits, -5000);
      expect(write.calculation.advancesTotal.minorUnits, 2500);
      expect(write.items.single.sourceType, DriverSettlementItemSourceType.manualAdjustment);
      expect(write.items.single.amount.minorUnits, 1250);
      expect(write.notes, 'snapshot');
    });

    test('blocks draft creation before financial resolution for viewer', () async {
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
      final useCase = CreateDriverSettlementDraftUseCase(
        moneyRepository: moneyRepository,
        resolveCalculation: createSettlementResolver(
          legacyRepository: legacyRepository,
          moneyRepository: moneyRepository,
          compensationRepository: compensationRepository,
          balanceRepository: balanceRepository,
        ),
      );

      final result = await useCase(
        CreateDriverSettlementDraftParams(
          currentCompanyContext: settlementTestContext(CompanyRole.viewer),
          driverId: testDriverId,
          periodStart: settlementTestDate(2026, 7, 1),
          periodEnd: settlementTestDate(2026, 7, 31),
        ),
      );

      expect(result, isA<FailureResult>());
      expect(
        result.failureOrNull?.code,
        FailureCodes.permissionDriverSettlementsManagement,
      );
      expect(compensationRepository.historyCalls, 0);
      expect(balanceRepository.calls, 0);
      expect(moneyRepository.snapshotCalls, 0);
      expect(moneyRepository.createDraftCalls, 0);
    });

    test('rejects inactive driver before compensation resolution', () async {
      final currency = CurrencyCode.tryParse('AED')!;
      final legacyRepository = FakeDriverSettlementsRepository(
        driverOption: const DriverSettlementDriverOption(
          id: testDriverId,
          displayName: 'Inactive Driver',
          isActive: false,
        ),
      );
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
          periodStart: settlementTestDate(2026, 7, 1),
          periodEnd: settlementTestDate(2026, 7, 31),
        ),
      );

      expect(result, isA<FailureResult>());
      expect(
        result.failureOrNull?.code,
        FailureCodes.validationDriverSettlementDriverInactive,
      );
      expect(compensationRepository.historyCalls, 0);
      expect(moneyRepository.snapshotCalls, 0);
    });
  });
}
