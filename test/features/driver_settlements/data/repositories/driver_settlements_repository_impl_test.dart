import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/driver_settlements/domain/entities/driver_settlement_period.dart';
import 'package:horus_system/features/driver_settlements/domain/entities/driver_settlement_source_snapshot.dart';
import 'package:horus_system/features/driver_settlements/domain/entities/driver_settlement_status.dart';
import 'package:test/test.dart';

import 'driver_settlements_repository_test_support.dart';

void main() {
  group('DriverSettlementsRepositoryImpl', () {
    test('creates draft and writes audit after successful mutation', () async {
      final operations = <String>[];
      final remoteDataSource = FakeDriverSettlementsRemoteDataSource(
        operations: operations,
      );
      final auditRepository = FakeDriverSettlementAuditLogRepository(
        operations: operations,
      );
      final repository = createDriverSettlementsRepository(
        remoteDataSource,
        auditRepository: auditRepository,
      );

      final result = await repository.createDraft(
        actorRole: testActorRole,
        data: draftWriteData(),
      );

      expect(result, isA<Success>());
      expect(result.dataOrNull?.id, testSettlementId);
      expect(remoteDataSource.createDraftCalls, 1);
      expect(operations, ['create_draft', 'audit']);
      expect(auditRepository.logs, hasLength(1));
      expect(
        auditRepository.logs.single.description,
        'driver_settlement_created',
      );
    });

    test('propagates create audit failure unchanged', () async {
      const auditFailure = ValidationFailure(
        code: 'audit_blocked',
        message: 'domain audit failure',
      );
      final remoteDataSource = FakeDriverSettlementsRemoteDataSource();
      final auditRepository = FakeDriverSettlementAuditLogRepository(
        failure: auditFailure,
      );
      final repository = createDriverSettlementsRepository(
        remoteDataSource,
        auditRepository: auditRepository,
      );

      final result = await repository.createDraft(
        actorRole: testActorRole,
        data: draftWriteData(),
      );

      expect(result, isA<FailureResult>());
      expect(result.failureOrNull, same(auditFailure));
      expect(remoteDataSource.createDraftCalls, 1);
    });

    test('finalizes after exact old snapshot lookup and audits last', () async {
      final operations = <String>[];
      final remoteDataSource = FakeDriverSettlementsRemoteDataSource(
        operations: operations,
      );
      final auditRepository = FakeDriverSettlementAuditLogRepository(
        operations: operations,
      );
      final repository = createDriverSettlementsRepository(
        remoteDataSource,
        auditRepository: auditRepository,
      );

      final result = await repository.finalizeSettlement(
        data: finalizeData,
        actorRole: testActorRole,
      );

      expect(result, isA<Success>());
      expect(result.dataOrNull?.status, DriverSettlementStatus.finalized);
      expect(operations, ['get_settlement', 'finalize_settlement', 'audit']);
      expect(remoteDataSource.lastLookupCompanyId, finalizeData.companyId);
      expect(
        remoteDataSource.lastLookupSettlementId,
        finalizeData.settlementId,
      );
      expect(
        auditRepository.logs.single.description,
        'driver_settlement_finalized',
      );
      expect(auditRepository.logs.single.oldValues?['status'], 'draft');
      expect(auditRepository.logs.single.newValues?['status'], 'finalized');
    });

    test('propagates finalize audit failure unchanged', () async {
      const auditFailure = ValidationFailure(
        code: 'audit_blocked',
        message: 'domain audit failure',
      );
      final operations = <String>[];
      final remoteDataSource = FakeDriverSettlementsRemoteDataSource(
        operations: operations,
      );
      final auditRepository = FakeDriverSettlementAuditLogRepository(
        failure: auditFailure,
        operations: operations,
      );
      final repository = createDriverSettlementsRepository(
        remoteDataSource,
        auditRepository: auditRepository,
      );

      final result = await repository.finalizeSettlement(
        data: finalizeData,
        actorRole: testActorRole,
      );

      expect(result, isA<FailureResult>());
      expect(result.failureOrNull, same(auditFailure));
      expect(operations, ['get_settlement', 'finalize_settlement', 'audit']);
    });

    test('voids after exact old snapshot lookup and audits last', () async {
      final operations = <String>[];
      final remoteDataSource = FakeDriverSettlementsRemoteDataSource(
        operations: operations,
      );
      final auditRepository = FakeDriverSettlementAuditLogRepository(
        operations: operations,
      );
      final repository = createDriverSettlementsRepository(
        remoteDataSource,
        auditRepository: auditRepository,
      );

      final result = await repository.voidSettlement(
        data: voidData,
        actorRole: testActorRole,
      );

      expect(result, isA<Success>());
      expect(result.dataOrNull?.status, DriverSettlementStatus.voided);
      expect(operations, ['get_settlement', 'void_settlement', 'audit']);
      expect(remoteDataSource.lastLookupCompanyId, voidData.companyId);
      expect(remoteDataSource.lastLookupSettlementId, voidData.settlementId);
      expect(
        auditRepository.logs.single.description,
        'driver_settlement_voided',
      );
      expect(auditRepository.logs.single.oldValues?['status'], 'draft');
      expect(auditRepository.logs.single.newValues?['status'], 'voided');
    });

    test('propagates void audit failure unchanged', () async {
      const auditFailure = ValidationFailure(
        code: 'audit_blocked',
        message: 'domain audit failure',
      );
      final operations = <String>[];
      final remoteDataSource = FakeDriverSettlementsRemoteDataSource(
        operations: operations,
      );
      final auditRepository = FakeDriverSettlementAuditLogRepository(
        failure: auditFailure,
        operations: operations,
      );
      final repository = createDriverSettlementsRepository(
        remoteDataSource,
        auditRepository: auditRepository,
      );

      final result = await repository.voidSettlement(
        data: voidData,
        actorRole: testActorRole,
      );

      expect(result, isA<FailureResult>());
      expect(result.failureOrNull, same(auditFailure));
      expect(operations, ['get_settlement', 'void_settlement', 'audit']);
    });

    test('uses exact period-bounded canonical balance as opening', () async {
      final period = DriverSettlementPeriod(
        start: DateTime(2026, 9),
        end: DateTime(2026, 9, 30),
      );
      final remoteDataSource = FakeDriverSettlementsRemoteDataSource(
        snapshot: const DriverSettlementSourceSnapshot(advancesTotal: 250),
      );
      final balanceRepository = FakeDriverBalanceRepository(
        result: Success(canonicalBalance(-5600)),
      );
      final repository = createDriverSettlementsRepository(
        remoteDataSource,
        balanceRepository: balanceRepository,
      );

      final result = await repository.getSettlementSourceSnapshot(
        companyId: testCompanyId,
        driverId: testDriverId,
        period: period,
      );

      expect(result, isA<Success>());
      expect(result.dataOrNull?.openingDriverBalance, -5600);
      expect(result.dataOrNull?.advancesTotal, 250);
      expect(balanceRepository.balanceCalls, 1);
      expect(balanceRepository.lastCompanyId, testCompanyId);
      expect(balanceRepository.lastDriverId, testDriverId);
      expect(balanceRepository.lastBeforeExclusive, period.start);
      expect(balanceRepository.lastCheckpointBeforeExclusive, period.start);
      expect(remoteDataSource.snapshotCalls, 1);
      expect(remoteDataSource.lastSnapshotCompanyId, testCompanyId);
      expect(remoteDataSource.lastSnapshotDriverId, testDriverId);
      expect(remoteDataSource.lastSnapshotPeriod, same(period));
    });

    test(
      'forwards company driver and includeVoided for settlement reads',
      () async {
        final remoteDataSource = FakeDriverSettlementsRemoteDataSource();
        final repository = createDriverSettlementsRepository(remoteDataSource);

        final result = await repository.getDriverSettlements(
          companyId: testCompanyId,
          driverId: testDriverId,
          includeVoided: true,
        );

        expect(result, isA<Success>());
        expect(remoteDataSource.lastListCompanyId, testCompanyId);
        expect(remoteDataSource.lastListDriverId, testDriverId);
        expect(remoteDataSource.lastIncludeVoided, isTrue);
      },
    );

    test('forwards company and settlement id for settlement lookup', () async {
      final remoteDataSource = FakeDriverSettlementsRemoteDataSource();
      final repository = createDriverSettlementsRepository(remoteDataSource);

      final result = await repository.getDriverSettlementById(
        companyId: testCompanyId,
        settlementId: testSettlementId,
      );

      expect(result, isA<Success>());
      expect(remoteDataSource.lastLookupCompanyId, testCompanyId);
      expect(remoteDataSource.lastLookupSettlementId, testSettlementId);
    });

    test('maps driver options with exact company forwarding', () async {
      final remoteDataSource = FakeDriverSettlementsRemoteDataSource();
      final repository = createDriverSettlementsRepository(remoteDataSource);

      final result = await repository.getDriverOptions(
        companyId: testCompanyId,
      );

      expect(result, isA<Success>());
      expect(result.dataOrNull?.single.displayName, 'Driver One');
      expect(result.dataOrNull?.single.isActive, isTrue);
      expect(remoteDataSource.lastDriverOptionsCompanyId, testCompanyId);
    });

    test(
      'maps driver option lookup with exact company and driver forwarding',
      () async {
        final remoteDataSource = FakeDriverSettlementsRemoteDataSource();
        final repository = createDriverSettlementsRepository(remoteDataSource);

        final result = await repository.getDriverOptionById(
          companyId: testCompanyId,
          driverId: testDriverId,
        );

        expect(result, isA<Success>());
        expect(result.dataOrNull?.id, testDriverId);
        expect(remoteDataSource.lastDriverOptionCompanyId, testCompanyId);
        expect(remoteDataSource.lastDriverOptionDriverId, testDriverId);
      },
    );
  });
}
