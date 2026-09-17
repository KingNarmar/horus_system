import 'package:horus_system/core/documents/domain/entities/business_document_access.dart';
import 'package:horus_system/core/documents/domain/entities/business_document_file.dart';
import 'package:horus_system/core/domain/value_objects/business_date.dart';
import 'package:horus_system/core/domain/value_objects/currency_code.dart';
import 'package:horus_system/core/domain/value_objects/currency_configuration.dart';
import 'package:horus_system/core/domain/value_objects/money.dart';
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
import 'package:horus_system/features/driver_settlements/domain/entities/driver_settlement_money_item.dart';
import 'package:horus_system/features/driver_settlements/domain/entities/driver_settlement_money_source_snapshot.dart';
import 'package:horus_system/features/driver_settlements/domain/entities/driver_settlement_period.dart';
import 'package:horus_system/features/driver_settlements/domain/entities/driver_settlement_source_snapshot.dart';
import 'package:horus_system/features/driver_settlements/domain/entities/driver_settlement_status.dart';
import 'package:horus_system/features/driver_settlements/domain/entities/driver_settlement_write_data.dart';
import 'package:horus_system/features/driver_settlements/domain/repositories/driver_settlement_money_repository.dart';
import 'package:horus_system/features/driver_settlements/domain/repositories/driver_settlements_repository.dart';
import 'package:horus_system/features/driver_settlements/domain/usecases/resolve_driver_settlement_calculation_usecase.dart';
import 'package:horus_system/features/drivers/domain/entities/driver_compensation_revision.dart';
import 'package:horus_system/features/drivers/domain/entities/driver_compensation_write_data.dart';
import 'package:horus_system/features/drivers/domain/repositories/driver_compensation_repository.dart';
import 'package:horus_system/features/drivers/domain/usecases/resolve_driver_compensation_for_period_usecase.dart';

const testCompanyId = 'company-1';
const testDriverId = 'driver-1';

BusinessDate settlementTestDate(int year, int month, int day) {
  return BusinessDate(year: year, month: month, day: day);
}

CurrentCompanyContext settlementTestContext(
  CompanyRole role, {
  String currencyCode = 'AED',
  int fractionDigits = 2,
}) {
  return CurrentCompanyContext(
    company: Company(
      id: testCompanyId,
      name: 'Company',
      baseCurrencyCode: currencyCode,
      baseCurrencyFractionDigits: fractionDigits,
    ),
    role: role,
  );
}

DriverCompensationRevision settlementTestRevision({
  String id = 'revision-1',
  required CurrencyCode currency,
  int fractionDigits = 2,
  required int amountMinorUnits,
  BusinessDate? effectiveFrom,
  BusinessDate? effectiveTo,
}) {
  return DriverCompensationRevision(
    id: id,
    companyId: testCompanyId,
    driverId: testDriverId,
    amount: Money(minorUnits: amountMinorUnits, currency: currency),
    currencyFractionDigits: fractionDigits,
    effectiveFrom: effectiveFrom ?? settlementTestDate(2026, 1, 1),
    effectiveTo: effectiveTo,
  );
}

DriverSettlementMoneySourceSnapshot settlementTestMoneySnapshot({
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

DriverMoneyBalance settlementTestMoneyBalance({
  required CurrencyCode currency,
  int fractionDigits = 2,
  int openingMinorUnits = 0,
}) {
  final zero = Money(minorUnits: 0, currency: currency);
  return DriverMoneyBalance(
    companyId: testCompanyId,
    driverId: testDriverId,
    currency: currency,
    currencyFractionDigits: fractionDigits,
    checkpoint: openingMinorUnits == 0
        ? null
        : DriverMoneyBalanceCheckpoint(
            settlementId: 'checkpoint-1',
            periodEnd: settlementTestDate(2026, 6, 30),
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

ResolveDriverSettlementCalculationUseCase createSettlementResolver({
  required FakeDriverSettlementsRepository legacyRepository,
  required FakeSettlementMoneyRepository moneyRepository,
  required FakeCompensationRepository compensationRepository,
  required FakeMoneyBalanceRepository balanceRepository,
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

final class FakeDriverSettlementsRepository
    implements DriverSettlementsRepository {
  final DriverSettlementDriverOption? driverOption;
  int voidCalls = 0;
  int driverOptionsCalls = 0;
  int driverOptionCalls = 0;

  FakeDriverSettlementsRepository({
    this.driverOption = const DriverSettlementDriverOption(
      id: testDriverId,
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
    return Success(
      settlementTestSettlement(status: DriverSettlementStatus.finalized),
    );
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
    return Success(settlementTestSettlement());
  }

  @override
  Future<Result<List<DriverSettlement>>> getDriverSettlements({
    required String companyId,
    String? driverId,
    bool includeVoided = false,
  }) async {
    return Success([settlementTestSettlement()]);
  }

  @override
  Future<Result<List<DriverSettlementDriverOption>>> getDriverOptions({
    required String companyId,
  }) async {
    driverOptionsCalls++;
    return const Success([
      DriverSettlementDriverOption(
        id: testDriverId,
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
    return Success(
      settlementTestSettlement(status: DriverSettlementStatus.voided),
    );
  }
}

final class FakeSettlementMoneyRepository
    implements DriverSettlementMoneyRepository {
  final DriverSettlementMoneySourceSnapshot snapshot;
  int snapshotCalls = 0;
  int createDraftCalls = 0;
  DriverSettlementMoneyDraftWriteData? lastWriteData;

  FakeSettlementMoneyRepository({required this.snapshot});

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
    return Success(settlementTestSettlement());
  }
}

final class FakeCompensationRepository implements DriverCompensationRepository {
  List<DriverCompensationRevision> history;
  int historyCalls = 0;

  FakeCompensationRepository(this.history);

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

final class FakeMoneyBalanceRepository implements DriverMoneyBalanceRepository {
  final DriverMoneyBalance balance;
  int calls = 0;
  BusinessDate? lastBeforeExclusive;
  BusinessDate? lastCheckpointBeforeExclusive;

  FakeMoneyBalanceRepository(this.balance);

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

DriverSettlement settlementTestSettlement({
  DriverSettlementStatus status = DriverSettlementStatus.draft,
}) {
  return DriverSettlement(
    id: 'settlement-1',
    companyId: testCompanyId,
    driverId: testDriverId,
    period: DriverSettlementPeriod(
      start: settlementTestDate(2026, 7, 1),
      end: settlementTestDate(2026, 7, 31),
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
