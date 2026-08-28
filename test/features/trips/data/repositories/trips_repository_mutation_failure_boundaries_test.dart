import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/trips/domain/entities/trip_entity.dart';
import 'package:horus_system/features/trips/domain/entities/trip_status.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;
import 'package:test/test.dart';

import 'trips_repository_test_support.dart';

void main() {
  group('TripsRepository mutation failure boundaries', () {
    test('sanitizes create persistence failure and stops before history', () async {
      final events = <String>[];
      final remoteDataSource = FakeTripsRemoteDataSource(
        events: events,
        errors: const {
          TripDataOperation.create: PostgrestException(
            message: 'insert failed',
            code: '23503',
            details: 'sensitive details',
            hint: 'sensitive hint',
          ),
        },
      );
      final auditRepository = FakeTripAuditLogRepository(events: events);
      final repository = createTripsRepository(
        remoteDataSource,
        auditRepository: auditRepository,
      );

      final result = await repository.createTrip(
        data: testTripWriteData,
        actorRole: 'owner',
      );

      expect(result, isA<FailureResult<TripEntity>>());
      expect(result.failureOrNull, isA<ServerFailure>());
      expect(result.failureOrNull?.code, FailureCodes.serverError);
      expect(result.failureOrNull?.message, isNull);
      expect(events, ['create']);
      expect(auditRepository.lastData, isNull);
    });

    test('sanitizes initial history failure and does not audit', () async {
      final events = <String>[];
      final remoteDataSource = FakeTripsRemoteDataSource(
        events: events,
        errors: const {
          TripDataOperation.history: PostgrestException(
            message: 'history insert failed',
            code: '42501',
          ),
        },
      );
      final auditRepository = FakeTripAuditLogRepository(events: events);
      final repository = createTripsRepository(
        remoteDataSource,
        auditRepository: auditRepository,
      );

      final result = await repository.createTrip(
        data: testTripWriteData,
        actorRole: 'owner',
      );

      expect(result, isA<FailureResult<TripEntity>>());
      expect(result.failureOrNull, isA<ServerFailure>());
      expect(result.failureOrNull?.code, FailureCodes.serverError);
      expect(result.failureOrNull?.message, isNull);
      expect(events, ['create', 'history']);
      expect(auditRepository.lastData, isNull);
    });

    test('sanitizes save persistence failure and does not audit', () async {
      final events = <String>[];
      final remoteDataSource = FakeTripsRemoteDataSource(
        currentModel: testOldTripModel,
        events: events,
        errors: const {
          TripDataOperation.save: PostgrestException(
            message: 'update failed',
            code: '42501',
          ),
        },
      );
      final auditRepository = FakeTripAuditLogRepository(events: events);
      final repository = createTripsRepository(
        remoteDataSource,
        auditRepository: auditRepository,
      );

      final result = await repository.saveTrip(
        id: testTripId,
        data: testTripWriteData,
        actorRole: 'operations',
      );

      expect(result, isA<FailureResult<TripEntity>>());
      expect(result.failureOrNull, isA<ServerFailure>());
      expect(result.failureOrNull?.code, FailureCodes.serverError);
      expect(result.failureOrNull?.message, isNull);
      expect(events, ['get', 'save']);
      expect(remoteDataSource.lastGetByIdCompanyId, testCompanyId);
      expect(remoteDataSource.lastGetByIdId, testTripId);
      expect(auditRepository.lastData, isNull);
    });

    test('sanitizes status persistence failure before history and audit', () async {
      final events = <String>[];
      final remoteDataSource = FakeTripsRemoteDataSource(
        currentModel: testOldTripModel,
        events: events,
        errors: const {
          TripDataOperation.status: PostgrestException(
            message: 'status update failed',
            code: '42501',
          ),
        },
      );
      final auditRepository = FakeTripAuditLogRepository(events: events);
      final repository = createTripsRepository(
        remoteDataSource,
        auditRepository: auditRepository,
      );

      final result = await repository.updateTripStatus(
        companyId: testCompanyId,
        id: testTripId,
        newStatus: TripStatus.loaded,
        actorRole: 'operations',
      );

      expect(result, isA<FailureResult<TripEntity>>());
      expect(result.failureOrNull, isA<ServerFailure>());
      expect(result.failureOrNull?.code, FailureCodes.serverError);
      expect(result.failureOrNull?.message, isNull);
      expect(events, ['get', 'status']);
      expect(auditRepository.lastData, isNull);
    });

    test('sanitizes status history runtime failure and does not audit', () async {
      final events = <String>[];
      final remoteDataSource = FakeTripsRemoteDataSource(
        currentModel: testOldTripModel,
        statusModel: testLoadedTripModel,
        events: events,
        errors: {
          TripDataOperation.history: Exception('history runtime detail'),
        },
      );
      final auditRepository = FakeTripAuditLogRepository(events: events);
      final repository = createTripsRepository(
        remoteDataSource,
        auditRepository: auditRepository,
      );

      final result = await repository.updateTripStatus(
        companyId: testCompanyId,
        id: testTripId,
        newStatus: TripStatus.loaded,
        actorRole: 'operations',
      );

      expect(result, isA<FailureResult<TripEntity>>());
      expect(result.failureOrNull, isA<UnexpectedFailure>());
      expect(result.failureOrNull?.code, FailureCodes.unexpectedError);
      expect(result.failureOrNull?.message, isNull);
      expect(events, ['get', 'status', 'history']);
      expect(auditRepository.lastData, isNull);
    });

    test('preserves unknown stored status fallback behavior', () async {
      final events = <String>[];
      final remoteDataSource = FakeTripsRemoteDataSource(
        currentModel: testUnknownStatusTripModel,
        statusModel: testLoadedTripModel,
        events: events,
      );
      final auditRepository = FakeTripAuditLogRepository(events: events);
      final repository = createTripsRepository(
        remoteDataSource,
        auditRepository: auditRepository,
      );

      final result = await repository.updateTripStatus(
        companyId: testCompanyId,
        id: testTripId,
        newStatus: TripStatus.loaded,
        actorRole: 'operations',
      );

      expect(result, isA<Success<TripEntity>>());
      expect(remoteDataSource.lastHistoryOldStatus, TripStatus.created);
      expect(events, ['get', 'status', 'history', 'audit:trip_status_changed']);
    });
  });
}
