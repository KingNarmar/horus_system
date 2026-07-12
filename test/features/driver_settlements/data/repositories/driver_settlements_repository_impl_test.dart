import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/audit/domain/entities/audit_entity_type.dart';
import 'package:horus_system/features/audit/domain/entities/audit_log.dart';
import 'package:horus_system/features/audit/domain/entities/audit_log_write_data.dart';
import 'package:horus_system/features/audit/domain/entities/audit_module.dart';
import 'package:horus_system/features/audit/domain/repositories/audit_log_repository.dart';
import 'package:horus_system/features/audit/domain/usecases/create_audit_log_usecase.dart';
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
      final remoteDataSource = _FakeDriverSettlementsRemoteDataSource();
      final auditRepository = _FakeAuditLogRepository();
      final repository = DriverSettlementsRepositoryImpl(
        remoteDataSource: remoteDataSource,
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

    test('gets source snapshot through remote datasource', () async {
      final remoteDataSource = _FakeDriverSettlementsRemoteDataSource(
        snapshot: const DriverSettlementSourceSnapshot(advancesTotal: 250),
      );
      final repository = DriverSettlementsRepositoryImpl(
        remoteDataSource: remoteDataSource,
        createAuditLogUseCase: CreateAuditLogUseCase(_FakeAuditLogRepository()),
      );

      final result = await repository.getSettlementSourceSnapshot(
        companyId: _companyId,
        driverId: _driverId,
        period: DriverSettlementPeriod(
          start: DateTime(2026, 7),
          end: DateTime(2026, 7, 31),
        ),
      );

      expect(result, isA<Success>());
      expect(result.dataOrNull?.advancesTotal, 250);
      expect(remoteDataSource.snapshotCalls, 1);
    });

    test('maps driver options without exposing data models', () async {
      final remoteDataSource = _FakeDriverSettlementsRemoteDataSource();
      final repository = DriverSettlementsRepositoryImpl(
        remoteDataSource: remoteDataSource,
        createAuditLogUseCase: CreateAuditLogUseCase(_FakeAuditLogRepository()),
      );

      final result = await repository.getDriverOptions(companyId: _companyId);

      expect(result, isA<Success>());
      expect(result.dataOrNull?.single.displayName, 'Driver One');
      expect(result.dataOrNull?.single.isActive, isTrue);
    });
  });
}

const _companyId = 'company-1';
const _driverId = 'driver-1';
const _settlementId = 'settlement-1';

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
  Future<List<DriverSettlementDriverOptionModel>> getDriverOptions({
    required String companyId,
  }) async {
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
    return const Success([]);
  }
}
