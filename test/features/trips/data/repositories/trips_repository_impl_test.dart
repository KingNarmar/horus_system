import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/audit/domain/entities/audit_action.dart';
import 'package:horus_system/features/audit/domain/entities/audit_entity_type.dart';
import 'package:horus_system/features/audit/domain/entities/audit_module.dart';
import 'package:horus_system/features/trips/domain/entities/trip_entity.dart';
import 'package:horus_system/features/trips/domain/entities/trip_status.dart';
import 'package:test/test.dart';

import 'trips_repository_test_support.dart';

void main() {
  group('TripsRepositoryImpl', () {
    test('create keeps mutation, initial history, audit ordering and config', () async {
      final events = <String>[];
      final remoteDataSource = FakeTripsRemoteDataSource(events: events);
      final auditRepository = FakeTripAuditLogRepository(events: events);
      final repository = createTripsRepository(
        remoteDataSource,
        auditRepository: auditRepository,
      );

      final result = await repository.createTrip(
        data: testTripWriteData,
        actorRole: 'owner',
        financialConfiguration: testFinancialConfiguration,
      );

      expect(result, isA<Success<TripEntity>>());
      expect(events, ['create', 'history', 'audit:trip_created']);
      expect(remoteDataSource.lastHistoryOldStatus, isNull);
      expect(
        remoteDataSource.lastCreateFinancialConfiguration,
        testFinancialConfiguration,
      );
      expect(auditRepository.lastData?.module, AuditModule.trips);
      expect(auditRepository.lastData?.entityType, AuditEntityType.trip);
      expect(auditRepository.lastData?.action, AuditAction.created);
      expect(auditRepository.lastData?.description, 'trip_created');
    });

    test('save reads old model then mutates then audits', () async {
      final events = <String>[];
      final remoteDataSource = FakeTripsRemoteDataSource(
        currentModel: testOldTripModel,
        events: events,
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
        financialConfiguration: testFinancialConfiguration,
      );

      expect(result, isA<Success<TripEntity>>());
      expect(events, ['get', 'save', 'audit:trip_updated']);
      expect(remoteDataSource.lastGetByIdCompanyId, testCompanyId);
      expect(
        remoteDataSource.lastSaveFinancialConfiguration,
        testFinancialConfiguration,
      );
      expect(auditRepository.lastData?.action, AuditAction.updated);
    });

    test('status update preserves history and audit ordering', () async {
      final events = <String>[];
      final remoteDataSource = FakeTripsRemoteDataSource(
        currentModel: testOldTripModel,
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
        financialConfiguration: testFinancialConfiguration,
        notes: 'Loaded at yard',
      );

      expect(result, isA<Success<TripEntity>>());
      expect(events, ['get', 'status', 'history', 'audit:trip_status_changed']);
      expect(remoteDataSource.lastHistoryOldStatus, TripStatus.assigned);
      expect(auditRepository.lastData?.action, AuditAction.statusChanged);
      expect(auditRepository.lastData?.metadata?['old_status'], 'assigned');
      expect(auditRepository.lastData?.metadata?['new_status'], 'loaded');
    });
  });
}
