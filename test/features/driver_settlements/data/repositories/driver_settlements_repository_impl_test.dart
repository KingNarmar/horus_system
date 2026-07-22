import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/audit/domain/entities/audit_entity_type.dart';
import 'package:horus_system/features/audit/domain/entities/audit_log.dart';
import 'package:horus_system/features/audit/domain/entities/audit_log_write_data.dart';
import 'package:horus_system/features/audit/domain/entities/audit_module.dart';
import 'package:horus_system/features/audit/domain/repositories/audit_log_repository.dart';
import 'package:horus_system/features/audit/domain/usecases/create_audit_log_usecase.dart';
import 'package:horus_system/features/driver_finance/domain/entities/driver_balance.dart';
import 'package:horus_system/features/driver_finance/domain/entities/driver_balance_checkpoint.dart';
import 'package:horus_system/features/driver_finance/domain/repositories/driver_balance_repository.dart';
import 'package:horus_system/features/driver_settlements/data/datasources/driver_settlements_remote_data_source.dart';
import 'package:horus_system/features/driver_settlements/data/models/driver_settlement_model.dart';
import 'package:horus_system/features/driver_settlements/data/repositories/driver_settlements_repository_impl.dart';
import 'package:horus_system/features/driver_settlements/domain/entities/driver_settlement_calculation_result.dart';
import 'package:horus_system/features/driver_settlements/domain/entities/driver_settlement_period.dart';
import 'package:horus_system/features/driver_settlements/domain/entities/driver_settlement_source_snapshot.dart';
import 'package:horus_system/features/driver_settlements/domain/entities/driver_settlement_status.dart';
import 'package:horus_system/features/driver_settlements/domain/entities/driver_settlement_write_data.dart';
import 'package:test/test.dart';

void main() {
  group('DriverSettlementsRepositoryImpl', () {
    test('creates draft and writes audit after successful mutation', () async {
      final remoteDataSource = _FakeDriverSettlementsRemoteDataSource();
      final auditRepository = _FakeAuditLogRepository();
      final repository = DriverSettlementsRepositoryImpl(
        remoteDataSource: remoteDataSource,
        driverBalanceRepository: _FakeDriverBalanceRepository(),
        createAuditLogUseCase: CreateAuditLogUseCase(auditRepository),
      );

      final result = await repository.createDraft(
        actorRole: 'accountant',
        data: _draftWriteData(),
      );

      expect(result, isA<Success>());
      expect(result.dataOrNull?.id, _settlementId);
      expect(remoteDataSource.createDraftCalls, 1);
      expect(auditRepository.logs, hasLength(1));
      expect(auditRepository.logs.single.companyId, _companyId);
      expect(auditRepository.logs.single.entityId, _driverId);
      expect(
        auditRepository.logs.single.description,
        'driver_settlement_created',
      );
      expect(
        auditRepository.logs.single.metadata?['settlement_id'],
        _settlementId,
      );
    });

    test('propagates audit failure after successful mutation', () async {
      final remoteDataSource = _FakeDriverSettlementsRemoteDataSource();
      final auditRepository = _FakeAuditLogRepository(
        failure: const ValidationFailure(code: FailureCodes.serverError),
      );
      final repository = DriverSettlementsRepositoryImpl(
        remoteDataSource: remoteDataSource,
        driverBalanceRepository: _FakeDriverBalanceRepository(),
        createAuditLogUseCase: CreateAuditLogUseCase(auditRepository),
      );

      final result = await repository.createDraft(
        actorRole: 'accountant',
        data: _draftWriteData(),
      );

      expect(result, isA<FailureResult>());
      expect(result.failureOrNull?.code, FailureCodes.serverError);
      expect(remoteDataSource.createDraftCalls, 1);
    });

    test('uses a period-bounded canonical balance as the opening', () async {
      final remoteDataSource = _FakeDriverSettlementsRemoteDataSource(
        snapshot: const DriverSettlementSourceSnapshot(advancesTotal: 250),
      );
      final balanceRepository = _FakeDriverBalanceRepository(
        balance: _canonicalBalance(-5600),
      );
      final repository = DriverSettlementsRepositoryImpl(
        remoteDataSource: remoteDataSource,
        driverBalanceRepository: balanceRepository,
        createAuditLogUseCase: CreateAuditLogUseCase(_FakeAuditLogRepository()),
      );
      final period = DriverSettlementPeriod(
        start: DateTime(2026, 9),
        end: DateTime(2026, 9, 30),
      );

      final result = await repository.getSettlementSourceSnapshot(
        companyId: _companyId,
        driverId: _driverId,
        period: period,
      );

      expect(result, isA<Success>());
      expect(result.dataOrNull?.openingDriverBalance, -5600);
      expect(result.dataOrNull?.advancesTotal, 250);
      expect(remoteDataSource.snapshotCalls, 1);
      expect(balanceRepository.balanceCalls, 1);
      expect(balanceRepository.lastCompanyId, _companyId);
      expect(balanceRepository.lastDriverId, _driverId);
      expect(balanceRepository.lastBeforeExclusive, period.start);
      expect(balanceRepository.lastCheckpointBeforeExclusive, period.start);
    });
  });
}

const _companyId = 'company-1';
const _driverId = 'driver-1';
const _settlementId = 'settlement-1';

DriverBalance _canonicalBalance(double closingBalance) {
  return DriverBalance(
    companyId: _companyId,
    driverId: _driverId,
    checkpoint: DriverBalanceCheckpoint(
      settlementId: 'checkpoint-1',
      periodEnd: DateTime(2026, 8, 31),
      snapshotCreatedAt: DateTime.utc(2026, 9, 1, 8),
      closingBalance: closingBalance,
    ),
    totalAdvances: 0,
    totalDriverCharges: 0,
  );
}

DriverSettlementDraftWriteData _draftWriteData() {
  return DriverSettlementDraftWriteData(
    companyId: _companyId,
    driverId: _driverId,
    period: DriverSettlementPeriod(
      start: DateTime(2026, 7),
      end: DateTime(2026, 7, 31),
    ),
    calculation: const DriverSettlementCalculationResult(
      openingDriverBalance: 0,
      advancesTotal: 200,
      driverPaidTripExpensesTotal: 50,
      returnedCashTotal: 0,
      deductionsTotal: 25,
      settlementDeductionsTotal: 0,
      grossSalary: 1000,
      salaryDeductionsTotal: 100,
      balanceDeductionApplied: 50,
      netSalaryPayable: 850,
      closingDriverBalance: 125,
    ),
  );
}

DriverSettlementModel _settlementModel({
  DriverSettlementStatus status = DriverSettlementStatus.draft,
}) {
  return DriverSettlementModel(
    id: _settlementId,
    companyId: _companyId,
    driverId: _driverId,
    periodStart: DateTime(2026, 7),
    periodEnd: DateTime(2026, 7, 31),
    openingDriverBalance: 0,
    advancesTotal: 200,
    driverPaidTripExpensesTotal: 50,
    returnedCashTotal: 0,
    deductionsTotal: 25,
    settlementDeductionsTotal: 0,
    grossSalary: 1000,
    salaryDeductionsTotal: 100,
    balanceDeductionApplied: 50,
    netSalaryPayable: 850,
    closingDriverBalance: 125,
    status: status,
  );
}

class _FakeDriverSettlementsRemoteDataSource
    implements DriverSettlementsRemoteDataSource {
  final DriverSettlementSourceSnapshot snapshot;
  int createDraftCalls = 0;
  int snapshotCalls = 0;

  _FakeDriverSettlementsRemoteDataSource({
    this.snapshot = const DriverSettlementSourceSnapshot(),
  });

  @override
  Future<DriverSettlementModel> createDraft({
    required DriverSettlementDraftWriteData data,
  }) async {
    createDraftCalls++;
    return _settlementModel();
  }

  @override
  Future<DriverSettlementModel> finalizeSettlement({
    required DriverSettlementFinalizeData data,
  }) async {
    return _settlementModel(status: DriverSettlementStatus.finalized);
  }

  @override
  Future<DriverSettlementModel> getDriverSettlementById({
    required String companyId,
    required String settlementId,
  }) async {
    return _settlementModel();
  }

  @override
  Future<List<DriverSettlementModel>> getDriverSettlements({
    required String companyId,
    String? driverId,
    bool includeVoided = false,
  }) async {
    return [_settlementModel()];
  }

  @override
  Future<DriverSettlementSourceSnapshot> getSettlementSourceSnapshot({
    required String companyId,
    required String driverId,
    required DriverSettlementPeriod period,
  }) async {
    snapshotCalls++;
    return snapshot;
  }

  @override
  Future<DriverSettlementModel> voidSettlement({
    required DriverSettlementVoidData data,
  }) async {
    return _settlementModel(status: DriverSettlementStatus.voided);
  }
}

class _FakeDriverBalanceRepository implements DriverBalanceRepository {
  final DriverBalance balance;
  int balanceCalls = 0;
  String? lastCompanyId;
  String? lastDriverId;
  DateTime? lastBeforeExclusive;
  DateTime? lastCheckpointBeforeExclusive;

  _FakeDriverBalanceRepository({DriverBalance? balance})
    : balance =
          balance ??
          const DriverBalance(
            companyId: _companyId,
            driverId: _driverId,
            totalAdvances: 0,
            totalDriverCharges: 0,
          );

  @override
  Future<Result<DriverBalance>> getCanonicalDriverBalance({
    required String companyId,
    required String driverId,
    required DateTime beforeExclusive,
    DateTime? checkpointBeforeExclusive,
  }) async {
    balanceCalls++;
    lastCompanyId = companyId;
    lastDriverId = driverId;
    lastBeforeExclusive = beforeExclusive;
    lastCheckpointBeforeExclusive = checkpointBeforeExclusive;
    return Success(balance);
  }
}

class _FakeAuditLogRepository implements AuditLogRepository {
  final ValidationFailure? failure;
  final List<AuditLogWriteData> logs = [];

  _FakeAuditLogRepository({this.failure});

  @override
  Future<Result<void>> createAuditLog({required AuditLogWriteData data}) async {
    if (failure != null) return FailureResult<void>(failure!);
    logs.add(data);
    return const Success<void>(null);
  }

  @override
  Future<Result<List<AuditLog>>> getEntityAuditLogs({
    required String companyId,
    required AuditModule module,
    required AuditEntityType entityType,
    required String entityId,
  }) async {
    return const Success<List<AuditLog>>([]);
  }
}
