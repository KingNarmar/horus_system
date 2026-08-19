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
import 'package:horus_system/features/driver_settlements/data/models/driver_settlement_driver_option_model.dart';
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
      final operations = <String>[];
      final remoteDataSource = _FakeDriverSettlementsRemoteDataSource(
        operations: operations,
      );
      final auditRepository = _FakeAuditLogRepository(operations: operations);
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
      expect(operations, ['create_draft', 'audit']);
      expect(auditRepository.logs, hasLength(1));
      expect(
        auditRepository.logs.single.description,
        'driver_settlement_created',
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

    test('finalizes after old snapshot lookup and audits last', () async {
      final operations = <String>[];
      final remoteDataSource = _FakeDriverSettlementsRemoteDataSource(
        operations: operations,
      );
      final auditRepository = _FakeAuditLogRepository(operations: operations);
      final repository = DriverSettlementsRepositoryImpl(
        remoteDataSource: remoteDataSource,
        driverBalanceRepository: _FakeDriverBalanceRepository(),
        createAuditLogUseCase: CreateAuditLogUseCase(auditRepository),
      );

      final result = await repository.finalizeSettlement(
        data: const DriverSettlementFinalizeData(
          companyId: _companyId,
          settlementId: _settlementId,
        ),
        actorRole: 'accountant',
      );

      expect(result, isA<Success>());
      expect(result.dataOrNull?.status, DriverSettlementStatus.finalized);
      expect(operations, ['get_settlement', 'finalize_settlement', 'audit']);
      expect(
        auditRepository.logs.single.description,
        'driver_settlement_finalized',
      );
      expect(auditRepository.logs.single.oldValues?['status'], 'draft');
      expect(auditRepository.logs.single.newValues?['status'], 'finalized');
    });

    test('voids after old snapshot lookup and audits last', () async {
      final operations = <String>[];
      final remoteDataSource = _FakeDriverSettlementsRemoteDataSource(
        operations: operations,
      );
      final auditRepository = _FakeAuditLogRepository(operations: operations);
      final repository = DriverSettlementsRepositoryImpl(
        remoteDataSource: remoteDataSource,
        driverBalanceRepository: _FakeDriverBalanceRepository(),
        createAuditLogUseCase: CreateAuditLogUseCase(auditRepository),
      );

      final result = await repository.voidSettlement(
        data: const DriverSettlementVoidData(
          companyId: _companyId,
          settlementId: _settlementId,
          reason: 'duplicate',
        ),
        actorRole: 'accountant',
      );

      expect(result, isA<Success>());
      expect(result.dataOrNull?.status, DriverSettlementStatus.voided);
      expect(operations, ['get_settlement', 'void_settlement', 'audit']);
      expect(
        auditRepository.logs.single.description,
        'driver_settlement_voided',
      );
      expect(auditRepository.logs.single.oldValues?['status'], 'draft');
      expect(auditRepository.logs.single.newValues?['status'], 'voided');
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

    test('maps driver options without exposing data models', () async {
      final remoteDataSource = _FakeDriverSettlementsRemoteDataSource();
      final repository = DriverSettlementsRepositoryImpl(
        remoteDataSource: remoteDataSource,
        driverBalanceRepository: _FakeDriverBalanceRepository(),
        createAuditLogUseCase: CreateAuditLogUseCase(_FakeAuditLogRepository()),
      );

      final result = await repository.getDriverOptions(companyId: _companyId);

      expect(result, isA<Success>());
      expect(result.dataOrNull?.single.displayName, 'Driver One');
      expect(result.dataOrNull?.single.isActive, isTrue);
      expect(remoteDataSource.driverOptionsCompanyId, _companyId);
    });

    test('maps a company-scoped driver option lookup', () async {
      final remoteDataSource = _FakeDriverSettlementsRemoteDataSource();
      final repository = DriverSettlementsRepositoryImpl(
        remoteDataSource: remoteDataSource,
        driverBalanceRepository: _FakeDriverBalanceRepository(),
        createAuditLogUseCase: CreateAuditLogUseCase(_FakeAuditLogRepository()),
      );

      final result = await repository.getDriverOptionById(
        companyId: _companyId,
        driverId: _driverId,
      );

      expect(result, isA<Success>());
      expect(result.dataOrNull?.id, _driverId);
      expect(remoteDataSource.driverOptionCompanyId, _companyId);
      expect(remoteDataSource.driverOptionDriverId, _driverId);
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
  final List<String>? operations;
  int createDraftCalls = 0;
  int snapshotCalls = 0;
  String? driverOptionsCompanyId;
  String? driverOptionCompanyId;
  String? driverOptionDriverId;

  _FakeDriverSettlementsRemoteDataSource({
    this.snapshot = const DriverSettlementSourceSnapshot(),
    this.operations,
  });

  @override
  Future<DriverSettlementModel> createDraft({
    required DriverSettlementDraftWriteData data,
  }) async {
    createDraftCalls++;
    operations?.add('create_draft');
    return _settlementModel();
  }

  @override
  Future<DriverSettlementModel> finalizeSettlement({
    required DriverSettlementFinalizeData data,
  }) async {
    operations?.add('finalize_settlement');
    return _settlementModel(status: DriverSettlementStatus.finalized);
  }

  @override
  Future<DriverSettlementDriverOptionModel?> getDriverOptionById({
    required String companyId,
    required String driverId,
  }) async {
    driverOptionCompanyId = companyId;
    driverOptionDriverId = driverId;
    return const DriverSettlementDriverOptionModel(
      id: _driverId,
      displayName: 'Driver One',
      isActive: true,
    );
  }

  @override
  Future<List<DriverSettlementDriverOptionModel>> getDriverOptions({
    required String companyId,
  }) async {
    driverOptionsCompanyId = companyId;
    return const [
      DriverSettlementDriverOptionModel(
        id: _driverId,
        displayName: 'Driver One',
        isActive: true,
      ),
    ];
  }

  @override
  Future<DriverSettlementModel> getDriverSettlementById({
    required String companyId,
    required String settlementId,
  }) async {
    operations?.add('get_settlement');
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
    operations?.add('void_settlement');
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
  final List<String>? operations;
  final List<AuditLogWriteData> logs = [];

  _FakeAuditLogRepository({this.failure, this.operations});

  @override
  Future<Result<void>> createAuditLog({required AuditLogWriteData data}) async {
    operations?.add('audit');
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
