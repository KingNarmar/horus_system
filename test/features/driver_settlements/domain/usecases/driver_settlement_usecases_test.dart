import 'package:horus_system/core/documents/domain/entities/business_document_access.dart';
import 'package:horus_system/core/documents/domain/entities/business_document_file.dart';
import 'package:horus_system/core/domain/value_objects/business_date.dart';
import 'package:horus_system/core/domain/value_objects/currency_code.dart';
import 'package:horus_system/core/domain/value_objects/currency_configuration.dart';
import 'package:horus_system/core/domain/value_objects/money.dart';
import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/entities/current_company_context.dart';
import 'package:horus_system/features/driver_finance/domain/entities/driver_money_balance.dart';
import 'package:horus_system/features/driver_finance/domain/entities/driver_money_balance_checkpoint.dart';
import 'package:horus_system/features/driver_finance/domain/repositories/driver_money_balance_repository.dart';
import 'package:horus_system/features/driver_finance/domain/usecases/get_canonical_driver_money_balance_usecase.dart';
import 'package:horus_system/features/driver_settlements/domain/entities/driver_settlement.dart';
import 'package:horus_system/features/driver_settlements/domain/entities/driver_settlement_calculation_result.dart';
import 'package:horus_system/features/driver_settlements/domain/entities/driver_settlement_driver_option.dart';
import 'package:horus_system/features/driver_settlements/domain/entities/driver_settlement_item_direction.dart';
import 'package:horus_system/features/driver_settlements/domain/entities/driver_settlement_item_source_type.dart';
import 'package:horus_system/features/driver_settlements/domain/entities/driver_settlement_money_item.dart';
import 'package:horus_system/features/driver_settlements/domain/entities/driver_settlement_money_source_snapshot.dart';
import 'package:horus_system/features/driver_settlements/domain/entities/driver_settlement_period.dart';
import 'package:horus_system/features/driver_settlements/domain/entities/driver_settlement_source_snapshot.dart';
import 'package:horus_system/features/driver_settlements/domain/entities/driver_settlement_status.dart';
import 'package:horus_system/features/driver_settlements/domain/entities/driver_settlement_write_data.dart';
import 'package:horus_system/features/driver_settlements/domain/failures/driver_settlement_failure_codes.dart';
import 'package:horus_system/features/driver_settlements/domain/repositories/driver_settlement_money_repository.dart';
import 'package:horus_system/features/driver_settlements/domain/repositories/driver_settlements_repository.dart';
import 'package:horus_system/features/driver_settlements/domain/usecases/driver_settlement_usecases.dart';
import 'package:horus_system/features/drivers/domain/entities/driver_compensation_revision.dart';
import 'package:horus_system/features/drivers/domain/entities/driver_compensation_write_data.dart';
import 'package:horus_system/features/drivers/domain/failures/driver_compensation_failure_codes.dart';
import 'package:horus_system/features/drivers/domain/repositories/driver_compensation_repository.dart';
import 'package:horus_system/features/drivers/domain/usecases/resolve_driver_compensation_for_period_usecase.dart';
import 'package:test/test.dart';

void main() {
  group('Driver settlement PC-09 orchestration', () {
    test('auto-resolves compensation and canonical exact sources', () async {
      final currency = CurrencyCode.tryParse('AED')!;
      final legacyRepository = _FakeDriverSettlementsRepository();
      final moneyRepository = _FakeSettlementMoneyRepository(
        snapshot: _moneySnapshot(
          currency: currency,
          advances: 30000,
          tripExpenses: 10000,
          returnedCash: 5000,
          deductions: 2500,
          items: [
            DriverSettlementMoneyItem(
              companyId: _companyId,
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
      final compensationRepository = _FakeCompensationRepository([
        _revision(currency: currency, amountMinorUnits: 100000),
      ]);
      final balanceRepository = _FakeMoneyBalanceRepository(
        _moneyBalance(currency: currency, openingMinorUnits: -10000),
      );
      final useCase = CalculateDriverSettlementPreviewUseCase(
        _resolver(
          legacyRepository: legacyRepository,
          moneyRepository: moneyRepository,
          compensationRepository: compensationRepository,
          balanceRepository: balanceRepository,
        ),
      );

      final result = await useCase(
        DriverSettlementCalculationParams(
          currentCompanyContext: _context(CompanyRole.owner),
          driverId: _driverId,
          periodStart: _date(2026, 7, 1),
          periodEnd: _date(2026, 7, 31),
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
      expect(preview.items, hasLength(1));
      expect(compensationRepository.historyCalls, 1);
      expect(balanceRepository.calls, 1);
      expect(balanceRepository.lastBeforeExclusive, _date(2026, 7, 1));
      expect(balanceRepository.lastCheckpointBeforeExclusive, _date(2026, 7, 1));
      expect(moneyRepository.snapshotCalls, 1);
    });

    test('supports three-decimal settlement input exactly', () async {
      final currency = CurrencyCode.tryParse('KWD')!;
      final legacyRepository = _FakeDriverSettlementsRepository();
      final moneyRepository = _FakeSettlementMoneyRepository(
        snapshot: _moneySnapshot(currency: currency),
      );
      final compensationRepository = _FakeCompensationRepository([
        _revision(
          currency: currency,
          fractionDigits: 3,
          amountMinorUnits: 123456,
        ),
      ]);
      final balanceRepository = _FakeMoneyBalanceRepository(
        _moneyBalance(
          currency: currency,
          fractionDigits: 3,
          openingMinorUnits: 0,
        ),
      );
      final useCase = CalculateDriverSettlementPreviewUseCase(
        _resolver(
          legacyRepository: legacyRepository,
          moneyRepository: moneyRepository,
          compensationRepository: compensationRepository,
          balanceRepository: balanceRepository,
        ),
      );

      final result = await useCase(
        DriverSettlementCalculationParams(
          currentCompanyContext: _context(
            CompanyRole.accountant,
            currencyCode: 'KWD',
            fractionDigits: 3,
          ),
          driverId: _driverId,
          periodStart: _date(2026, 7, 1),
          periodEnd: _date(2026, 7, 31),
          salaryDeductionsTotal: '0.456',
        ),
      );

      expect(result, isA<Success>());
      expect(result.dataOrNull!.calculation.grossSalary.minorUnits, 123456);
      expect(result.dataOrNull!.calculation.salaryDeductionsTotal.minorUnits, 456);
      expect(result.dataOrNull!.calculation.netSalaryPayable.minorUnits, 123000);
    });

    test('rejects over-precision before loading financial sources', () async {
      final currency = CurrencyCode.tryParse('AED')!;
      final legacyRepository = _FakeDriverSettlementsRepository();
      final moneyRepository = _FakeSettlementMoneyRepository(
        snapshot: _moneySnapshot(currency: currency),
      );
      final compensationRepository = _FakeCompensationRepository([
        _revision(currency: currency, amountMinorUnits: 100000),
      ]);
      final balanceRepository = _FakeMoneyBalanceRepository(
        _moneyBalance(currency: currency),
      );
      final useCase = CalculateDriverSettlementPreviewUseCase(
        _resolver(
          legacyRepository: legacyRepository,
          moneyRepository: moneyRepository,
          compensationRepository: compensationRepository,
          balanceRepository: balanceRepository,
        ),
      );

      final result = await useCase(
        DriverSettlementCalculationParams(
          currentCompanyContext: _context(CompanyRole.accountant),
          driverId: _driverId,
          periodStart: _date(2026, 7, 1),
          periodEnd: _date(2026, 7, 31),
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
      final legacyRepository = _FakeDriverSettlementsRepository();
      final moneyRepository = _FakeSettlementMoneyRepository(
        snapshot: _moneySnapshot(currency: currency),
      );
      final compensationRepository = _FakeCompensationRepository([
        _revision(
          id: 'old',
          currency: currency,
          amountMinorUnits: 100000,
          effectiveFrom: _date(2026, 7, 1),
          effectiveTo: _date(2026, 7, 15),
        ),
        _revision(
          id: 'new',
          currency: currency,
          amountMinorUnits: 110000,
          effectiveFrom: _date(2026, 7, 16),
        ),
      ]);
      final balanceRepository = _FakeMoneyBalanceRepository(
        _moneyBalance(currency: currency),
      );
      final useCase = CalculateDriverSettlementPreviewUseCase(
        _resolver(
          legacyRepository: legacyRepository,
          moneyRepository: moneyRepository,
          compensationRepository: compensationRepository,
          balanceRepository: balanceRepository,
        ),
      );

      final result = await useCase(
        DriverSettlementCalculationParams(
          currentCompanyContext: _context(CompanyRole.accountant),
          driverId: _driverId,
          periodStart: _date(2026, 7, 1),
          periodEnd: _date(2026, 7, 31),
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
      final legacyRepository = _FakeDriverSettlementsRepository();
      final moneyRepository = _FakeSettlementMoneyRepository(
        snapshot: _moneySnapshot(currency: currency),
      );
      final compensationRepository = _FakeCompensationRepository([
        _revision(currency: currency, amountMinorUnits: 50000),
      ]);
      final balanceRepository = _FakeMoneyBalanceRepository(
        _moneyBalance(currency: currency, openingMinorUnits: -10000),
      );
      final useCase = CalculateDriverSettlementPreviewUseCase(
        _resolver(
          legacyRepository: legacyRepository,
          moneyRepository: moneyRepository,
          compensationRepository: compensationRepository,
          balanceRepository: balanceRepository,
        ),
      );

      final result = await useCase(
        DriverSettlementCalculationParams(
          currentCompanyContext: _context(CompanyRole.accountant),
          driverId: _driverId,
          periodStart: _date(2026, 7, 1),
          periodEnd: _date(2026, 7, 31),
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
      final legacyRepository = _FakeDriverSettlementsRepository();
      final moneyRepository = _FakeSettlementMoneyRepository(
        snapshot: _moneySnapshot(currency: currency, advances: 2500),
      );
      final compensationRepository = _FakeCompensationRepository([
        _revision(currency: currency, amountMinorUnits: 100000),
      ]);
      final balanceRepository = _FakeMoneyBalanceRepository(
        _moneyBalance(currency: currency, openingMinorUnits: -5000),
      );
      final resolver = _resolver(
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
          currentCompanyContext: _context(CompanyRole.accountant),
          driverId: _driverId,
          periodStart: _date(2026, 7, 1),
          periodEnd: _date(2026, 7, 31),
          salaryDeductionsTotal: '10.00',
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
      expect(write.notes, 'snapshot');
    });

    test('blocks draft creation before financial resolution for viewer', () async {
      final currency = CurrencyCode.tryParse('AED')!;
      final legacyRepository = _FakeDriverSettlementsRepository();
      final moneyRepository = _FakeSettlementMoneyRepository(
        snapshot: _moneySnapshot(currency: currency),
      );
      final compensationRepository = _FakeCompensationRepository([
        _revision(currency: currency, amountMinorUnits: 100000),
      ]);
      final balanceRepository = _FakeMoneyBalanceRepository(
        _moneyBalance(currency: currency),
      );
      final useCase = CreateDriverSettlementDraftUseCase(
        moneyRepository: moneyRepository,
        resolveCalculation: _resolver(
          legacyRepository: legacyRepository,
          moneyRepository: moneyRepository,
          compensationRepository: compensationRepository,
          balanceRepository: balanceRepository,
        ),
      );

      final result = await useCase(
        CreateDriverSettlementDraftParams(
          currentCompanyContext: _context(CompanyRole.viewer),
          driverId: _driverId,
          periodStart: _date(2026, 7, 1),
          periodEnd: _date(2026, 7, 31),
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
      final legacyRepository = _FakeDriverSettlementsRepository(
        driverOption: const DriverSettlementDriverOption(
          id: _driverId,
          displayName: 'Inactive Driver',
          isActive: false,
        ),
      );
      final moneyRepository = _FakeSettlementMoneyRepository(
        snapshot: _moneySnapshot(currency: currency),
      );
      final compensationRepository = _FakeCompensationRepository([
        _revision(currency: currency, amountMinorUnits: 100000),
      ]);
      final balanceRepository = _FakeMoneyBalanceRepository(
        _moneyBalance(currency: currency),
      );
      final useCase = CalculateDriverSettlementPreviewUseCase(
        _resolver(
          legacyRepository: legacyRepository,
          moneyRepository: moneyRepository,
          compensationRepository: compensationRepository,
          balanceRepository: balanceRepository,
        ),
      );

      final result = await useCase(
        DriverSettlementCalculationParams(
          currentCompanyContext: _context(CompanyRole.accountant),
          driverId: _driverId,
          periodStart: _date(2026, 7, 1),
          periodEnd: _date(2026, 7, 31),
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

  group('Driver settlement existing commands', () {
    test('loads company-scoped driver options for finance roles', () async {
      final repository = _FakeDriverSettlementsRepository();
      final useCase = GetDriverSettlementDriverOptionsUseCase(repository);

      final result = await useCase(
        GetDriverSettlementDriverOptionsParams(
          currentCompanyContext: _context(CompanyRole.accountant),
        ),
      );

      expect(result, isA<Success>());
      expect(result.dataOrNull, hasLength(1));
      expect(repository.driverOptionsCalls, 1);
    });

    test('rejects invalid settlement periods before repository access', () async {
      final currency = CurrencyCode.tryParse('AED')!;
      final legacyRepository = _FakeDriverSettlementsRepository();
      final moneyRepository = _FakeSettlementMoneyRepository(
        snapshot: _moneySnapshot(currency: currency),
      );
      final compensationRepository = _FakeCompensationRepository([
        _revision(currency: currency, amountMinorUnits: 100000),
      ]);
      final balanceRepository = _FakeMoneyBalanceRepository(
        _moneyBalance(currency: currency),
      );
      final useCase = CalculateDriverSettlementPreviewUseCase(
        _resolver(
          legacyRepository: legacyRepository,
          moneyRepository: moneyRepository,
          compensationRepository: compensationRepository,
          balanceRepository: balanceRepository,
        ),
      );

      final result = await useCase(
        DriverSettlementCalculationParams(
          currentCompanyContext: _context(CompanyRole.accountant),
          driverId: _driverId,
          periodStart: _date(2026, 8, 1),
          periodEnd: _date(2026, 7, 1),
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
      final repository = _FakeDriverSettlementsRepository();
      final useCase = VoidDriverSettlementUseCase(repository);

      final result = await useCase(
        VoidDriverSettlementParams(
          currentCompanyContext: _context(CompanyRole.admin),
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

const _companyId = 'company-1';
const _driverId = 'driver-1';

BusinessDate _date(int year, int month, int day) {
  return BusinessDate(year: year, month: month, day: day);
}

CurrentCompanyContext _context(
  CompanyRole role, {
  String currencyCode = 'AED',
  int fractionDigits = 2,
}) {
  return CurrentCompanyContext(
    company: Company(
      id: _companyId,
      name: 'Company',
      baseCurrencyCode: currencyCode,
      baseCurrencyFractionDigits: fractionDigits,
    ),
    role: role,
  );
}

DriverCompensationRevision _revision({
  String id = 'revision-1',
  required CurrencyCode currency,
  int fractionDigits = 2,
  required int amountMinorUnits,
  BusinessDate? effectiveFrom,
  BusinessDate? effectiveTo,
}) {
  return DriverCompensationRevision(
    id: id,
    companyId: _companyId,
    driverId: _driverId,
    amount: Money(minorUnits: amountMinorUnits, currency: currency),
    currencyFractionDigits: fractionDigits,
    effectiveFrom: effectiveFrom ?? _date(2026, 1, 1),
    effectiveTo: effectiveTo,
  );
}

DriverSettlementMoneySourceSnapshot _moneySnapshot({
  required CurrencyCode currency,
  int advances = 0,
  int tripExpenses = 0,
  int returnedCash = 0,
  int deductions = 0,
  List<DriverSettlementMoneyItem> items = const [],
}) {
  return DriverSettlementMoneySourceSnapshot(
    openingDriverBalance: Money(minorUnits: 0, currency: currency),
    advancesTotal: Money(minorUnits: advances, currency: currency),
    driverPaidTripExpensesTotal: Money(
      minorUnits: tripExpenses,
      currency: currency,
    ),
    returnedCashTotal: Money(minorUnits: returnedCash, currency: currency),
    deductionsTotal: Money(minorUnits: deductions, currency: currency),
    sourceItems: items,
  );
}

DriverMoneyBalance _moneyBalance({
  required CurrencyCode currency,
  int fractionDigits = 2,
  int openingMinorUnits = 0,
}) {
  final zero = Money(minorUnits: 0, currency: currency);
  return DriverMoneyBalance(
    companyId: _companyId,
    driverId: _driverId,
    currency: currency,
    currencyFractionDigits: fractionDigits,
    checkpoint: openingMinorUnits == 0
        ? null
        : DriverMoneyBalanceCheckpoint(
            settlementId: 'checkpoint-1',
            periodEnd: _date(2026, 6, 30),
            snapshotCreatedAt: DateTime.utc(2026, 7, 1),
            closingBalance: Money(
              minorUnits: openingMinorUnits,
              currency: currency,
            ),
            currencyFractionDigits: fractionDigits,
          ),
    totalAdvances: zero,
    totalDriverCharges: zero,
    totalTripExpenseCredits: zero,
    totalCashReturns: zero,
  );
}

ResolveDriverSettlementCalculationUseCase _resolver({
  required _FakeDriverSettlementsRepository legacyRepository,
  required _FakeSettlementMoneyRepository moneyRepository,
  required _FakeCompensationRepository compensationRepository,
  required _FakeMoneyBalanceRepository balanceRepository,
}) {
  return ResolveDriverSettlementCalculationUseCase(
    repository: legacyRepository,
    moneyRepository: moneyRepository,
    resolveCompensation: ResolveDriverCompensationForPeriodUseCase(
      compensationRepository,
    ),
    getCanonicalMoneyBalance: GetCanonicalDriverMoneyBalanceUseCase(
      balanceRepository,
    ),
  );
}

class _FakeDriverSettlementsRepository implements DriverSettlementsRepository {
  final DriverSettlementDriverOption? driverOption;
  int voidCalls = 0;
  int driverOptionsCalls = 0;
  int driverOptionCalls = 0;

  _FakeDriverSettlementsRepository({
    this.driverOption = const DriverSettlementDriverOption(
      id: _driverId,
      displayName: 'Driver',
      isActive: true,
    ),
  });

  @override
  Future<Result<DriverSettlement>> createDraft({
    required DriverSettlementDraftWriteData data,
    required String actorRole,
  }) {
    throw UnsupportedError('Legacy draft path is not used by PC-09 tests.');
  }

  @override
  Future<Result<DriverSettlement>> finalizeSettlement({
    required DriverSettlementFinalizeData data,
    required String actorRole,
  }) async {
    return Success(_settlement(status: DriverSettlementStatus.finalized));
  }

  @override
  Future<Result<DriverSettlementDriverOption?>> getDriverOptionById({
    required String companyId,
    required String driverId,
  }) async {
    driverOptionCalls++;
    return Success(driverOption);
  }

  @override
  Future<Result<DriverSettlement>> getDriverSettlementById({
    required String companyId,
    required String settlementId,
  }) async {
    return Success(_settlement());
  }

  @override
  Future<Result<List<DriverSettlement>>> getDriverSettlements({
    required String companyId,
    String? driverId,
    bool includeVoided = false,
  }) async {
    return Success([_settlement()]);
  }

  @override
  Future<Result<List<DriverSettlementDriverOption>>> getDriverOptions({
    required String companyId,
  }) async {
    driverOptionsCalls++;
    return const Success([
      DriverSettlementDriverOption(
        id: _driverId,
        displayName: 'Driver',
        isActive: true,
      ),
    ]);
  }

  @override
  Future<Result<DriverSettlementSourceSnapshot>> getSettlementSourceSnapshot({
    required String companyId,
    required String driverId,
    required DriverSettlementPeriod period,
  }) {
    throw UnsupportedError('Legacy source path is not used by PC-09 tests.');
  }

  @override
  Future<Result<DriverSettlement>> voidSettlement({
    required DriverSettlementVoidData data,
    required String actorRole,
  }) async {
    voidCalls++;
    return Success(_settlement(status: DriverSettlementStatus.voided));
  }
}

class _FakeSettlementMoneyRepository implements DriverSettlementMoneyRepository {
  final DriverSettlementMoneySourceSnapshot snapshot;
  int snapshotCalls = 0;
  int createDraftCalls = 0;
  DriverSettlementMoneyDraftWriteData? lastWriteData;

  _FakeSettlementMoneyRepository({required this.snapshot});

  @override
  Future<Result<DriverSettlementMoneySourceSnapshot>>
  getSettlementMoneySourceSnapshot({
    required String companyId,
    required String driverId,
    required DriverSettlementPeriod period,
    required CurrencyConfiguration currencyConfiguration,
  }) async {
    snapshotCalls++;
    return Success(snapshot);
  }

  @override
  Future<Result<DriverSettlement>> createMoneyDraft({
    required DriverSettlementMoneyDraftWriteData data,
    required String actorRole,
  }) async {
    createDraftCalls++;
    lastWriteData = data;
    return Success(_settlement());
  }
}

class _FakeCompensationRepository implements DriverCompensationRepository {
  List<DriverCompensationRevision> history;
  int historyCalls = 0;

  _FakeCompensationRepository(this.history);

  @override
  Future<Result<List<DriverCompensationRevision>>> getHistory({
    required String companyId,
    required String driverId,
  }) async {
    historyCalls++;
    return Success(history);
  }

  @override
  Future<Result<DriverCompensationRevision>> createRevision({
    required DriverCompensationWriteData data,
    required String actorRole,
    BusinessDocumentFile? contractDocument,
  }) {
    throw UnsupportedError('Not used by settlement tests.');
  }

  @override
  Future<Result<DriverCompensationRevision>> endRevision({
    required String companyId,
    required String revisionId,
    required String driverId,
    required String actorRole,
    required BusinessDate effectiveTo,
  }) {
    throw UnsupportedError('Not used by settlement tests.');
  }

  @override
  Future<Result<DriverCompensationRevision>> attachContractDocument({
    required DriverCompensationRevision revision,
    required String actorRole,
    required BusinessDocumentFile document,
  }) {
    throw UnsupportedError('Not used by settlement tests.');
  }

  @override
  Future<Result<BusinessDocumentAccess>> createContractDocumentAccess({
    required String companyId,
    required DriverCompensationRevision revision,
  }) {
    throw UnsupportedError('Not used by settlement tests.');
  }
}

class _FakeMoneyBalanceRepository implements DriverMoneyBalanceRepository {
  final DriverMoneyBalance balance;
  int calls = 0;
  BusinessDate? lastBeforeExclusive;
  BusinessDate? lastCheckpointBeforeExclusive;

  _FakeMoneyBalanceRepository(this.balance);

  @override
  Future<Result<DriverMoneyBalance>> getCanonicalDriverMoneyBalance({
    required String companyId,
    required String driverId,
    required CurrencyCode currency,
    required int currencyFractionDigits,
    required BusinessDate beforeExclusive,
    BusinessDate? checkpointBeforeExclusive,
  }) async {
    calls++;
    lastBeforeExclusive = beforeExclusive;
    lastCheckpointBeforeExclusive = checkpointBeforeExclusive;
    return Success(balance);
  }
}

DriverSettlement _settlement({
  DriverSettlementStatus status = DriverSettlementStatus.draft,
}) {
  return DriverSettlement(
    id: 'settlement-1',
    companyId: _companyId,
    driverId: _driverId,
    period: DriverSettlementPeriod(
      start: _date(2026, 7, 1),
      end: _date(2026, 7, 31),
    ),
    calculation: const DriverSettlementCalculationResult(
      openingDriverBalance: 0,
      advancesTotal: 0,
      driverPaidTripExpensesTotal: 0,
      returnedCashTotal: 0,
      deductionsTotal: 0,
      settlementDeductionsTotal: 0,
      grossSalary: 0,
      salaryDeductionsTotal: 0,
      balanceDeductionApplied: 0,
      netSalaryPayable: 0,
      closingDriverBalance: 0,
    ),
    status: status,
  );
}
