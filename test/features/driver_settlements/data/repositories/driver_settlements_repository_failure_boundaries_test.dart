import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/driver_finance/domain/entities/driver_balance.dart';
import 'package:horus_system/features/driver_settlements/domain/entities/driver_settlement_period.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;
import 'package:test/test.dart';

import 'driver_settlements_repository_test_support.dart';

void main() {
  group('DriverSettlementsRepositoryImpl failure boundaries', () {
    test(
      'sanitizes Postgrest list failure and preserves exact read scope',
      () async {
        const backendError = PostgrestException(
          message: 'sensitive list message',
          code: '42501',
          details: 'sensitive list details',
          hint: 'sensitive list hint',
        );
        final remoteDataSource = FakeDriverSettlementsRemoteDataSource(
          listError: backendError,
        );
        final repository = createDriverSettlementsRepository(remoteDataSource);

        final result = await repository.getDriverSettlements(
          companyId: testCompanyId,
          driverId: testDriverId,
          includeVoided: true,
        );

        expect(result, isA<FailureResult>());
        expect(result.failureOrNull, isA<ServerFailure>());
        expect(result.failureOrNull?.code, FailureCodes.serverError);
        expect(result.failureOrNull?.message, isNull);
        expect(remoteDataSource.lastListCompanyId, testCompanyId);
        expect(remoteDataSource.lastListDriverId, testDriverId);
        expect(remoteDataSource.lastIncludeVoided, isTrue);
      },
    );

    test(
      'sanitizes Postgrest settlement lookup failure and preserves scope',
      () async {
        const backendError = PostgrestException(
          message: 'sensitive lookup message',
          code: 'PGRST116',
          details: 'sensitive lookup details',
          hint: 'sensitive lookup hint',
        );
        final remoteDataSource = FakeDriverSettlementsRemoteDataSource(
          lookupError: backendError,
        );
        final repository = createDriverSettlementsRepository(remoteDataSource);

        final result = await repository.getDriverSettlementById(
          companyId: testCompanyId,
          settlementId: testSettlementId,
        );

        expect(result, isA<FailureResult>());
        expect(result.failureOrNull, isA<ServerFailure>());
        expect(result.failureOrNull?.code, FailureCodes.serverError);
        expect(result.failureOrNull?.message, isNull);
        expect(remoteDataSource.lastLookupCompanyId, testCompanyId);
        expect(remoteDataSource.lastLookupSettlementId, testSettlementId);
      },
    );

    test('sanitizes model-to-entity mapping failures inside guard', () async {
      final remoteDataSource = FakeDriverSettlementsRemoteDataSource(
        listModels: [ThrowingDriverSettlementModel()],
      );
      final repository = createDriverSettlementsRepository(remoteDataSource);

      final result = await repository.getDriverSettlements(
        companyId: testCompanyId,
        driverId: testDriverId,
      );

      expect(result, isA<FailureResult>());
      expect(result.failureOrNull, isA<UnexpectedFailure>());
      expect(result.failureOrNull?.code, FailureCodes.unexpectedError);
      expect(result.failureOrNull?.message, isNull);
    });

    test(
      'propagates typed Driver Finance failure unchanged and stops snapshot',
      () async {
        const driverFinanceFailure = ValidationFailure(
          code: 'canonical_balance_unavailable',
          message: 'typed driver finance failure',
        );
        final period = DriverSettlementPeriod(
          start: DateTime(2026, 9),
          end: DateTime(2026, 9, 30),
        );
        final remoteDataSource = FakeDriverSettlementsRemoteDataSource();
        final balanceRepository = FakeDriverBalanceRepository(
          result: const FailureResult<DriverBalance>(driverFinanceFailure),
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

        expect(result, isA<FailureResult>());
        expect(result.failureOrNull, same(driverFinanceFailure));
        expect(balanceRepository.lastCompanyId, testCompanyId);
        expect(balanceRepository.lastDriverId, testDriverId);
        expect(balanceRepository.lastBeforeExclusive, period.start);
        expect(balanceRepository.lastCheckpointBeforeExclusive, period.start);
        expect(remoteDataSource.snapshotCalls, 0);
      },
    );

    test(
      'sanitizes thrown balance repository exception and stops snapshot',
      () async {
        final period = DriverSettlementPeriod(
          start: DateTime(2026, 9),
          end: DateTime(2026, 9, 30),
        );
        final remoteDataSource = FakeDriverSettlementsRemoteDataSource();
        final balanceRepository = FakeDriverBalanceRepository(
          error: StateError('balance internal detail'),
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

        expect(result, isA<FailureResult>());
        expect(result.failureOrNull, isA<UnexpectedFailure>());
        expect(result.failureOrNull?.code, FailureCodes.unexpectedError);
        expect(result.failureOrNull?.message, isNull);
        expect(remoteDataSource.snapshotCalls, 0);
      },
    );

    test(
      'sanitizes remote snapshot failure after successful canonical balance',
      () async {
        const backendError = PostgrestException(
          message: 'sensitive snapshot message',
          code: '42501',
          details: 'sensitive snapshot details',
          hint: 'sensitive snapshot hint',
        );
        final period = DriverSettlementPeriod(
          start: DateTime(2026, 9),
          end: DateTime(2026, 9, 30),
        );
        final remoteDataSource = FakeDriverSettlementsRemoteDataSource(
          snapshotError: backendError,
        );
        final balanceRepository = FakeDriverBalanceRepository(
          result: Success(canonicalBalance(100)),
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

        expect(result, isA<FailureResult>());
        expect(result.failureOrNull, isA<ServerFailure>());
        expect(result.failureOrNull?.code, FailureCodes.serverError);
        expect(result.failureOrNull?.message, isNull);
        expect(balanceRepository.balanceCalls, 1);
        expect(remoteDataSource.snapshotCalls, 1);
        expect(remoteDataSource.lastSnapshotCompanyId, testCompanyId);
        expect(remoteDataSource.lastSnapshotDriverId, testDriverId);
        expect(remoteDataSource.lastSnapshotPeriod, same(period));
      },
    );

    test('sanitizes create mutation failure and stops before audit', () async {
      final operations = <String>[];
      const backendError = PostgrestException(
        message: 'sensitive create message',
        code: '42501',
        details: 'sensitive create details',
        hint: 'sensitive create hint',
      );
      final remoteDataSource = FakeDriverSettlementsRemoteDataSource(
        operations: operations,
        createError: backendError,
      );
      final auditRepository = FakeDriverSettlementAuditLogRepository(
        operations: operations,
      );
      final repository = createDriverSettlementsRepository(
        remoteDataSource,
        auditRepository: auditRepository,
      );

      final result = await repository.createDraft(
        data: draftWriteData(),
        actorRole: testActorRole,
      );

      expect(result, isA<FailureResult>());
      expect(result.failureOrNull, isA<ServerFailure>());
      expect(result.failureOrNull?.code, FailureCodes.serverError);
      expect(result.failureOrNull?.message, isNull);
      expect(operations, ['create_draft']);
      expect(auditRepository.logs, isEmpty);
    });

    test(
      'stops finalize before mutation and audit when old lookup fails',
      () async {
        final operations = <String>[];
        final remoteDataSource = FakeDriverSettlementsRemoteDataSource(
          operations: operations,
          lookupError: StateError('old snapshot internal detail'),
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

        expect(result, isA<FailureResult>());
        expect(result.failureOrNull, isA<UnexpectedFailure>());
        expect(result.failureOrNull?.code, FailureCodes.unexpectedError);
        expect(result.failureOrNull?.message, isNull);
        expect(remoteDataSource.lastLookupCompanyId, finalizeData.companyId);
        expect(
          remoteDataSource.lastLookupSettlementId,
          finalizeData.settlementId,
        );
        expect(remoteDataSource.finalizeCalls, 0);
        expect(operations, ['get_settlement']);
        expect(auditRepository.logs, isEmpty);
      },
    );

    test('stops finalize before audit when mutation fails', () async {
      final operations = <String>[];
      const backendError = PostgrestException(
        message: 'sensitive finalize message',
        code: '42501',
      );
      final remoteDataSource = FakeDriverSettlementsRemoteDataSource(
        operations: operations,
        finalizeError: backendError,
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

      expect(result, isA<FailureResult>());
      expect(result.failureOrNull, isA<ServerFailure>());
      expect(result.failureOrNull?.code, FailureCodes.serverError);
      expect(result.failureOrNull?.message, isNull);
      expect(operations, ['get_settlement', 'finalize_settlement']);
      expect(auditRepository.logs, isEmpty);
    });

    test(
      'stops void before mutation and audit when old lookup fails',
      () async {
        final operations = <String>[];
        const backendError = PostgrestException(
          message: 'sensitive old snapshot message',
          code: '42501',
        );
        final remoteDataSource = FakeDriverSettlementsRemoteDataSource(
          operations: operations,
          lookupError: backendError,
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

        expect(result, isA<FailureResult>());
        expect(result.failureOrNull, isA<ServerFailure>());
        expect(result.failureOrNull?.code, FailureCodes.serverError);
        expect(result.failureOrNull?.message, isNull);
        expect(remoteDataSource.lastLookupCompanyId, voidData.companyId);
        expect(remoteDataSource.lastLookupSettlementId, voidData.settlementId);
        expect(remoteDataSource.voidCalls, 0);
        expect(operations, ['get_settlement']);
        expect(auditRepository.logs, isEmpty);
      },
    );

    test('stops void before audit when mutation fails', () async {
      final operations = <String>[];
      final remoteDataSource = FakeDriverSettlementsRemoteDataSource(
        operations: operations,
        voidError: StateError('void internal detail'),
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

      expect(result, isA<FailureResult>());
      expect(result.failureOrNull, isA<UnexpectedFailure>());
      expect(result.failureOrNull?.code, FailureCodes.unexpectedError);
      expect(result.failureOrNull?.message, isNull);
      expect(operations, ['get_settlement', 'void_settlement']);
      expect(auditRepository.logs, isEmpty);
    });
  });
}
