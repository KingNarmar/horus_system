import 'package:horus_system/core/errors/failure.dart';
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

const testCompanyId = 'company-1';
const testDriverId = 'driver-1';
const testSettlementId = 'settlement-1';
const testActorRole = 'accountant';

DriverSettlementsRepositoryImpl createDriverSettlementsRepository(
  FakeDriverSettlementsRemoteDataSource remoteDataSource, {
  FakeDriverBalanceRepository? balanceRepository,
  FakeDriverSettlementAuditLogRepository? auditRepository,
}) {
  return DriverSettlementsRepositoryImpl(
    remoteDataSource: remoteDataSource,
    driverBalanceRepository: balanceRepository ?? FakeDriverBalanceRepository(),
    createAuditLogUseCase: CreateAuditLogUseCase(
      auditRepository ?? FakeDriverSettlementAuditLogRepository(),
    ),
  );
}

DriverBalance canonicalBalance(double closingBalance) {
  return DriverBalance(
    companyId: testCompanyId,
    driverId: testDriverId,
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

DriverSettlementDraftWriteData draftWriteData() {
  return DriverSettlementDraftWriteData(
    companyId: testCompanyId,
    driverId: testDriverId,
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

const finalizeData = DriverSettlementFinalizeData(
  companyId: testCompanyId,
  settlementId: testSettlementId,
);

const voidData = DriverSettlementVoidData(
  companyId: testCompanyId,
  settlementId: testSettlementId,
  reason: 'duplicate',
);

DriverSettlementModel settlementModel({
  DriverSettlementStatus status = DriverSettlementStatus.draft,
}) {
  return DriverSettlementModel(
    id: testSettlementId,
    companyId: testCompanyId,
    driverId: testDriverId,
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

class ThrowingDriverSettlementModel extends DriverSettlementModel {
  ThrowingDriverSettlementModel()
    : super(
        id: 'settlement-broken',
        companyId: testCompanyId,
        driverId: testDriverId,
        periodStart: DateTime(2026, 7),
        periodEnd: DateTime(2026, 7, 31),
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
        status: DriverSettlementStatus.draft,
      );

  @override
  double get openingDriverBalance =>
      throw StateError('mapping internal detail');
}

class FakeDriverSettlementsRemoteDataSource
    implements DriverSettlementsRemoteDataSource {
  final List<String>? operations;
  final Object? listError;
  final Object? driverOptionsError;
  final Object? driverOptionError;
  final Object? lookupError;
  final Object? snapshotError;
  final Object? createError;
  final Object? finalizeError;
  final Object? voidError;
  final List<DriverSettlementModel>? listModels;
  final DriverSettlementSourceSnapshot snapshot;

  int listCalls = 0;
  int driverOptionsCalls = 0;
  int driverOptionCalls = 0;
  int lookupCalls = 0;
  int snapshotCalls = 0;
  int createDraftCalls = 0;
  int finalizeCalls = 0;
  int voidCalls = 0;

  String? lastListCompanyId;
  String? lastListDriverId;
  bool? lastIncludeVoided;
  String? lastDriverOptionsCompanyId;
  String? lastDriverOptionCompanyId;
  String? lastDriverOptionDriverId;
  String? lastLookupCompanyId;
  String? lastLookupSettlementId;
  String? lastSnapshotCompanyId;
  String? lastSnapshotDriverId;
  DriverSettlementPeriod? lastSnapshotPeriod;

  FakeDriverSettlementsRemoteDataSource({
    this.operations,
    this.listError,
    this.driverOptionsError,
    this.driverOptionError,
    this.lookupError,
    this.snapshotError,
    this.createError,
    this.finalizeError,
    this.voidError,
    this.listModels,
    this.snapshot = const DriverSettlementSourceSnapshot(),
  });

  @override
  Future<List<DriverSettlementModel>> getDriverSettlements({
    required String companyId,
    String? driverId,
    bool includeVoided = false,
  }) async {
    listCalls++;
    lastListCompanyId = companyId;
    lastListDriverId = driverId;
    lastIncludeVoided = includeVoided;
    operations?.add('get_settlements');
    if (listError != null) throw listError!;
    return listModels ?? [settlementModel()];
  }

  @override
  Future<List<DriverSettlementDriverOptionModel>> getDriverOptions({
    required String companyId,
  }) async {
    driverOptionsCalls++;
    lastDriverOptionsCompanyId = companyId;
    if (driverOptionsError != null) throw driverOptionsError!;
    return const [
      DriverSettlementDriverOptionModel(
        id: testDriverId,
        displayName: 'Driver One',
        isActive: true,
      ),
    ];
  }

  @override
  Future<DriverSettlementDriverOptionModel?> getDriverOptionById({
    required String companyId,
    required String driverId,
  }) async {
    driverOptionCalls++;
    lastDriverOptionCompanyId = companyId;
    lastDriverOptionDriverId = driverId;
    if (driverOptionError != null) throw driverOptionError!;
    return const DriverSettlementDriverOptionModel(
      id: testDriverId,
      displayName: 'Driver One',
      isActive: true,
    );
  }

  @override
  Future<DriverSettlementModel> getDriverSettlementById({
    required String companyId,
    required String settlementId,
  }) async {
    lookupCalls++;
    lastLookupCompanyId = companyId;
    lastLookupSettlementId = settlementId;
    operations?.add('get_settlement');
    if (lookupError != null) throw lookupError!;
    return settlementModel();
  }

  @override
  Future<DriverSettlementSourceSnapshot> getSettlementSourceSnapshot({
    required String companyId,
    required String driverId,
    required DriverSettlementPeriod period,
  }) async {
    snapshotCalls++;
    lastSnapshotCompanyId = companyId;
    lastSnapshotDriverId = driverId;
    lastSnapshotPeriod = period;
    operations?.add('get_source_snapshot');
    if (snapshotError != null) throw snapshotError!;
    return snapshot;
  }

  @override
  Future<DriverSettlementModel> createDraft({
    required DriverSettlementDraftWriteData data,
  }) async {
    createDraftCalls++;
    operations?.add('create_draft');
    if (createError != null) throw createError!;
    return settlementModel();
  }

  @override
  Future<DriverSettlementModel> finalizeSettlement({
    required DriverSettlementFinalizeData data,
  }) async {
    finalizeCalls++;
    operations?.add('finalize_settlement');
    if (finalizeError != null) throw finalizeError!;
    return settlementModel(status: DriverSettlementStatus.finalized);
  }

  @override
  Future<DriverSettlementModel> voidSettlement({
    required DriverSettlementVoidData data,
  }) async {
    voidCalls++;
    operations?.add('void_settlement');
    if (voidError != null) throw voidError!;
    return settlementModel(status: DriverSettlementStatus.voided);
  }
}

class FakeDriverBalanceRepository implements DriverBalanceRepository {
  final Result<DriverBalance>? result;
  final Object? error;

  int balanceCalls = 0;
  String? lastCompanyId;
  String? lastDriverId;
  DateTime? lastBeforeExclusive;
  DateTime? lastCheckpointBeforeExclusive;

  FakeDriverBalanceRepository({this.result, this.error});

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

    if (error != null) throw error!;
    return result ?? Success(canonicalBalance(0));
  }
}

class FakeDriverSettlementAuditLogRepository implements AuditLogRepository {
  final Failure? failure;
  final List<String>? operations;
  final List<AuditLogWriteData> logs = [];

  FakeDriverSettlementAuditLogRepository({this.failure, this.operations});

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
