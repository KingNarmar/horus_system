import 'package:horus_system/core/domain/value_objects/currency_code.dart';
import 'package:horus_system/core/domain/value_objects/currency_configuration.dart';
import 'package:horus_system/core/domain/value_objects/money.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/audit/domain/usecases/create_audit_log_usecase.dart';
import 'package:horus_system/features/driver_settlements/data/datasources/driver_settlement_money_remote_data_source.dart';
import 'package:horus_system/features/driver_settlements/data/models/driver_settlement_model.dart';
import 'package:horus_system/features/driver_settlements/data/repositories/driver_settlements_repository_impl.dart';
import 'package:horus_system/features/driver_settlements/domain/entities/driver_settlement_money_calculation_result.dart';
import 'package:horus_system/features/driver_settlements/domain/entities/driver_settlement_money_source_snapshot.dart';
import 'package:horus_system/features/driver_settlements/domain/entities/driver_settlement_period.dart';
import 'package:horus_system/features/driver_settlements/domain/entities/driver_settlement_status.dart';
import 'package:horus_system/features/driver_settlements/domain/entities/driver_settlement_write_data.dart';
import 'package:test/test.dart';

import 'driver_settlements_repository_test_support.dart';

void main() {
  group('DriverSettlementsRepositoryImpl exact money path', () {
    test('forwards tenant period and currency to exact source loader', () async {
      final currency = CurrencyCode.tryParse('AED')!;
      final configuration = CurrencyConfiguration(
        currency: currency,
        fractionDigits: 2,
      );
      final zero = Money(minorUnits: 0, currency: currency);
      final expected = DriverSettlementMoneySourceSnapshot(
        openingDriverBalance: zero,
        advancesTotal: Money(minorUnits: 10005, currency: currency),
        driverPaidTripExpensesTotal: zero,
        returnedCashTotal: zero,
        deductionsTotal: zero,
      );
      final moneyRemote = _FakeMoneyRemoteDataSource(snapshot: expected);
      final repository = _repository(moneyRemote: moneyRemote);
      final period = DriverSettlementPeriod(
        start: testBusinessDate(2026, 7, 1),
        end: testBusinessDate(2026, 7, 31),
      );

      final result = await repository.getSettlementMoneySourceSnapshot(
        companyId: testCompanyId,
        driverId: testDriverId,
        period: period,
        currencyConfiguration: configuration,
      );

      expect(result, isA<Success<DriverSettlementMoneySourceSnapshot>>());
      expect(result.dataOrNull, same(expected));
      expect(moneyRemote.snapshotCalls, 1);
      expect(moneyRemote.lastCompanyId, testCompanyId);
      expect(moneyRemote.lastDriverId, testDriverId);
      expect(moneyRemote.lastPeriod, same(period));
      expect(moneyRemote.lastCurrencyConfiguration, configuration);
    });

    test('creates exact draft then writes enriched audit', () async {
      final currency = CurrencyCode.tryParse('AED')!;
      final write = _moneyWriteData(currency);
      final operations = <String>[];
      final moneyRemote = _FakeMoneyRemoteDataSource(
        createModel: _exactModel(),
        operations: operations,
      );
      final auditRepository = FakeDriverSettlementAuditLogRepository(
        operations: operations,
      );
      final repository = _repository(
        moneyRemote: moneyRemote,
        auditRepository: auditRepository,
      );

      final result = await repository.createMoneyDraft(
        data: write,
        actorRole: testActorRole,
      );

      expect(result, isA<Success>());
      expect(moneyRemote.createCalls, 1);
      expect(moneyRemote.lastWriteData, same(write));
      expect(operations, ['create_money_draft', 'audit']);
      expect(auditRepository.logs, hasLength(1));
      final audit = auditRepository.logs.single;
      expect(audit.description, 'driver_settlement_created');
      expect(audit.metadata?['compensation_revision_id'], 'revision-1');
      expect(audit.metadata?['currency_code'], 'AED');
      expect(audit.metadata?['currency_fraction_digits'], 2);
      expect(audit.metadata?['gross_salary_minor_units'], 100000);
      expect(audit.metadata?['net_salary_payable_minor_units'], 85000);
      expect(audit.metadata?['closing_driver_balance_minor_units'], -12500);
    });
  });
}

DriverSettlementsRepositoryImpl _repository({
  required _FakeMoneyRemoteDataSource moneyRemote,
  FakeDriverSettlementAuditLogRepository? auditRepository,
}) {
  return DriverSettlementsRepositoryImpl(
    remoteDataSource: FakeDriverSettlementsRemoteDataSource(),
    moneyRemoteDataSource: moneyRemote,
    driverBalanceRepository: FakeDriverBalanceRepository(),
    createAuditLogUseCase: CreateAuditLogUseCase(
      auditRepository ?? FakeDriverSettlementAuditLogRepository(),
    ),
  );
}

DriverSettlementMoneyDraftWriteData _moneyWriteData(CurrencyCode currency) {
  return DriverSettlementMoneyDraftWriteData(
    companyId: testCompanyId,
    driverId: testDriverId,
    period: DriverSettlementPeriod(
      start: testBusinessDate(2026, 7, 1),
      end: testBusinessDate(2026, 7, 31),
    ),
    compensationRevisionId: 'revision-1',
    currencyFractionDigits: 2,
    calculation: DriverSettlementMoneyCalculationResult(
      openingDriverBalance: Money(minorUnits: -10000, currency: currency),
      advancesTotal: Money(minorUnits: 5000, currency: currency),
      driverPaidTripExpensesTotal: Money(minorUnits: 2500, currency: currency),
      returnedCashTotal: Money(minorUnits: 1000, currency: currency),
      deductionsTotal: Money(minorUnits: 500, currency: currency),
      settlementDeductionsTotal: Money(minorUnits: 500, currency: currency),
      grossSalary: Money(minorUnits: 100000, currency: currency),
      salaryDeductionsTotal: Money(minorUnits: 10000, currency: currency),
      balanceDeductionApplied: Money(minorUnits: 5000, currency: currency),
      netSalaryPayable: Money(minorUnits: 85000, currency: currency),
      closingDriverBalance: Money(minorUnits: -12500, currency: currency),
    ),
  );
}

DriverSettlementModel _exactModel() {
  return DriverSettlementModel(
    id: testSettlementId,
    companyId: testCompanyId,
    driverId: testDriverId,
    periodStart: testBusinessDate(2026, 7, 1),
    periodEnd: testBusinessDate(2026, 7, 31),
    compensationRevisionId: 'revision-1',
    currencyCode: 'AED',
    currencyFractionDigits: 2,
    openingDriverBalance: -100,
    openingDriverBalanceMinorUnits: -10000,
    advancesTotal: 50,
    advancesTotalMinorUnits: 5000,
    driverPaidTripExpensesTotal: 25,
    driverPaidTripExpensesTotalMinorUnits: 2500,
    returnedCashTotal: 10,
    returnedCashTotalMinorUnits: 1000,
    deductionsTotal: 5,
    deductionsTotalMinorUnits: 500,
    settlementDeductionsTotal: 5,
    settlementDeductionsTotalMinorUnits: 500,
    grossSalary: 1000,
    grossSalaryMinorUnits: 100000,
    salaryDeductionsTotal: 100,
    salaryDeductionsTotalMinorUnits: 10000,
    balanceDeductionApplied: 50,
    balanceDeductionAppliedMinorUnits: 5000,
    netSalaryPayable: 850,
    netSalaryPayableMinorUnits: 85000,
    closingDriverBalance: -125,
    closingDriverBalanceMinorUnits: -12500,
    status: DriverSettlementStatus.draft,
  );
}

final class _FakeMoneyRemoteDataSource
    implements DriverSettlementMoneyRemoteDataSource {
  final DriverSettlementMoneySourceSnapshot? snapshot;
  final DriverSettlementModel? createModel;
  final List<String>? operations;

  int snapshotCalls = 0;
  int createCalls = 0;
  String? lastCompanyId;
  String? lastDriverId;
  DriverSettlementPeriod? lastPeriod;
  CurrencyConfiguration? lastCurrencyConfiguration;
  DriverSettlementMoneyDraftWriteData? lastWriteData;

  _FakeMoneyRemoteDataSource({
    this.snapshot,
    this.createModel,
    this.operations,
  });

  @override
  Future<DriverSettlementMoneySourceSnapshot> getSettlementMoneySourceSnapshot({
    required String companyId,
    required String driverId,
    required DriverSettlementPeriod period,
    required CurrencyConfiguration currencyConfiguration,
  }) async {
    snapshotCalls++;
    lastCompanyId = companyId;
    lastDriverId = driverId;
    lastPeriod = period;
    lastCurrencyConfiguration = currencyConfiguration;
    final value = snapshot;
    if (value == null) throw StateError('Exact snapshot was not configured.');
    return value;
  }

  @override
  Future<DriverSettlementModel> createMoneyDraft({
    required DriverSettlementMoneyDraftWriteData data,
  }) async {
    createCalls++;
    lastWriteData = data;
    operations?.add('create_money_draft');
    final value = createModel;
    if (value == null) throw StateError('Exact draft model was not configured.');
    return value;
  }
}
