import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/audit/domain/entities/audit_action.dart';
import 'package:horus_system/features/audit/domain/entities/audit_entity_type.dart';
import 'package:horus_system/features/audit/domain/entities/audit_log.dart';
import 'package:horus_system/features/audit/domain/entities/audit_log_write_data.dart';
import 'package:horus_system/features/audit/domain/entities/audit_module.dart';
import 'package:horus_system/features/audit/domain/repositories/audit_log_repository.dart';
import 'package:horus_system/features/audit/domain/usecases/create_audit_log_usecase.dart';
import 'package:horus_system/features/trips/data/datasources/trips_remote_data_source.dart';
import 'package:horus_system/features/trips/data/models/trip_model.dart';
import 'package:horus_system/features/trips/data/models/trip_status_history_model.dart';
import 'package:horus_system/features/trips/data/repositories/trips_repository_impl.dart';
import 'package:horus_system/features/trips/domain/entities/trip_form_lookups.dart';
import 'package:horus_system/features/trips/domain/entities/trip_status.dart';
import 'package:horus_system/features/trips/domain/entities/trip_write_data.dart';
import 'package:test/test.dart';

void main() {
  group('TripsRepositoryImpl', () {
    test('preserves create, initial history, then audit ordering', () async {
      final events = <String>[];
      final remoteDataSource = _FakeTripsRemoteDataSource(
        currentModel: _createdTripModel,
        createModel: _createdTripModel,
        events: events,
      );
      final auditRepository = _FakeAuditLogRepository(events: events);
      final repository = TripsRepositoryImpl(
        remoteDataSource: remoteDataSource,
        createAuditLogUseCase: CreateAuditLogUseCase(auditRepository),
      );

      final result = await repository.createTrip(
        data: _writeData,
        actorRole: 'owner',
      );

      expect(result, isA<Success>());
      expect(events, ['create', 'history', 'audit:trip_created']);
      expect(remoteDataSource.lastHistoryOldStatus, isNull);
      expect(remoteDataSource.lastHistoryNewStatus, TripStatus.created);
      expect(remoteDataSource.lastHistoryActorRole, 'owner');

      expect(auditRepository.lastData, isNotNull);
      final audit = auditRepository.lastData!;
      expect(audit.companyId, _companyId);
      expect(audit.module, AuditModule.trips);
      expect(audit.entityType, AuditEntityType.trip);
      expect(audit.entityId, _tripId);
      expect(audit.entityDisplayName, 'LO-001');
      expect(audit.action, AuditAction.created);
      expect(audit.description, 'trip_created');
      expect(audit.oldValues, isNull);
      expect(audit.newValues?['status'], 'created');
    });

    test('preserves old and new audit snapshots when saving a trip', () async {
      final events = <String>[];
      final remoteDataSource = _FakeTripsRemoteDataSource(
        currentModel: _oldTripModel,
        saveModel: _updatedTripModel,
        events: events,
      );
      final auditRepository = _FakeAuditLogRepository(events: events);
      final repository = TripsRepositoryImpl(
        remoteDataSource: remoteDataSource,
        createAuditLogUseCase: CreateAuditLogUseCase(auditRepository),
      );

      final result = await repository.saveTrip(
        id: _tripId,
        data: _writeData,
        actorRole: 'operations',
      );

      expect(result, isA<Success>());
      expect(events, ['get', 'save', 'audit:trip_updated']);
      expect(remoteDataSource.lastGetByIdCompanyId, _companyId);

      expect(auditRepository.lastData, isNotNull);
      final audit = auditRepository.lastData!;
      expect(audit.actorRole, 'operations');
      expect(audit.action, AuditAction.updated);
      expect(audit.description, 'trip_updated');
      expect(audit.oldValues?['waybill_number'], 'WB-OLD');
      expect(audit.newValues?['waybill_number'], 'WB-NEW');
    });

    test('preserves status history and audit metadata ordering', () async {
      final events = <String>[];
      final remoteDataSource = _FakeTripsRemoteDataSource(
        currentModel: _oldTripModel,
        statusModel: _loadedTripModel,
        events: events,
      );
      final auditRepository = _FakeAuditLogRepository(events: events);
      final repository = TripsRepositoryImpl(
        remoteDataSource: remoteDataSource,
        createAuditLogUseCase: CreateAuditLogUseCase(auditRepository),
      );

      final result = await repository.updateTripStatus(
        companyId: _companyId,
        id: _tripId,
        newStatus: TripStatus.loaded,
        actorRole: 'operations',
        notes: 'Loaded at yard',
      );

      expect(result, isA<Success>());
      expect(
        events,
        ['get', 'status', 'history', 'audit:trip_status_changed'],
      );
      expect(remoteDataSource.lastGetByIdCompanyId, _companyId);
      expect(remoteDataSource.lastStatusCompanyId, _companyId);
      expect(remoteDataSource.lastHistoryCompanyId, _companyId);
      expect(remoteDataSource.lastHistoryOldStatus, TripStatus.assigned);
      expect(remoteDataSource.lastHistoryNewStatus, TripStatus.loaded);
      expect(remoteDataSource.lastHistoryActorRole, 'operations');
      expect(remoteDataSource.lastHistoryNotes, 'Loaded at yard');

      expect(auditRepository.lastData, isNotNull);
      final audit = auditRepository.lastData!;
      expect(audit.companyId, _companyId);
      expect(audit.action, AuditAction.statusChanged);
      expect(audit.description, 'trip_status_changed');
      expect(audit.oldValues?['status'], 'assigned');
      expect(audit.newValues?['status'], 'loaded');
      expect(audit.metadata?['old_status'], 'assigned');
      expect(audit.metadata?['new_status'], 'loaded');
      expect(audit.metadata?['notes'], 'Loaded at yard');
    });

    test('propagates audit failure after successful trip creation', () async {
      final events = <String>[];
      final remoteDataSource = _FakeTripsRemoteDataSource(
        currentModel: _createdTripModel,
        createModel: _createdTripModel,
        events: events,
      );
      final auditRepository = _FakeAuditLogRepository(
        events: events,
        createResult: const FailureResult<void>(
          ServerFailure(code: 'audit_failure'),
        ),
      );
      final repository = TripsRepositoryImpl(
        remoteDataSource: remoteDataSource,
        createAuditLogUseCase: CreateAuditLogUseCase(auditRepository),
      );

      final result = await repository.createTrip(
        data: _writeData,
        actorRole: 'owner',
      );

      expect(result, isA<FailureResult>());
      expect(result.failureOrNull?.code, 'audit_failure');
      expect(events, ['create', 'history', 'audit:trip_created']);
    });
  });
}

const _companyId = 'company-1';
const _tripId = 'trip-1';

const _writeData = TripWriteData(
  companyId: _companyId,
  customerId: 'customer-1',
  routeId: 'route-1',
  driverId: 'driver-1',
  tractorHeadId: 'tractor-1',
  trailerId: 'trailer-1',
  loadingOrderNumber: 'LO-001',
  waybillNumber: 'WB-NEW',
  notes: 'Trip notes',
);

const _createdTripModel = TripModel(
  id: _tripId,
  companyId: _companyId,
  customerId: 'customer-1',
  routeId: 'route-1',
  driverId: 'driver-1',
  tractorHeadId: 'tractor-1',
  trailerId: 'trailer-1',
  status: 'created',
  loadingOrderNumber: 'LO-001',
  waybillNumber: 'WB-NEW',
  customerName: 'Customer One',
  routeName: 'Dubai -> Abu Dhabi',
);

const _oldTripModel = TripModel(
  id: _tripId,
  companyId: _companyId,
  customerId: 'customer-1',
  routeId: 'route-1',
  driverId: 'driver-1',
  tractorHeadId: 'tractor-1',
  trailerId: 'trailer-1',
  status: 'assigned',
  loadingOrderNumber: 'LO-001',
  waybillNumber: 'WB-OLD',
  customerName: 'Customer One',
  routeName: 'Dubai -> Abu Dhabi',
);

const _updatedTripModel = TripModel(
  id: _tripId,
  companyId: _companyId,
  customerId: 'customer-1',
  routeId: 'route-1',
  driverId: 'driver-1',
  tractorHeadId: 'tractor-1',
  trailerId: 'trailer-1',
  status: 'assigned',
  loadingOrderNumber: 'LO-001',
  waybillNumber: 'WB-NEW',
  customerName: 'Customer One',
  routeName: 'Dubai -> Abu Dhabi',
);

const _loadedTripModel = TripModel(
  id: _tripId,
  companyId: _companyId,
  customerId: 'customer-1',
  routeId: 'route-1',
  driverId: 'driver-1',
  tractorHeadId: 'tractor-1',
  trailerId: 'trailer-1',
  status: 'loaded',
  loadingOrderNumber: 'LO-001',
  waybillNumber: 'WB-OLD',
  customerName: 'Customer One',
  routeName: 'Dubai -> Abu Dhabi',
);

class _FakeTripsRemoteDataSource implements TripsRemoteDataSource {
  final TripModel currentModel;
  final TripModel? createModel;
  final TripModel? saveModel;
  final TripModel? statusModel;
  final List<String> events;

  String? lastGetByIdCompanyId;
  String? lastStatusCompanyId;
  String? lastHistoryCompanyId;
  TripStatus? lastHistoryOldStatus;
  TripStatus? lastHistoryNewStatus;
  String? lastHistoryActorRole;
  String? lastHistoryNotes;

  _FakeTripsRemoteDataSource({
    required this.currentModel,
    required this.events,
    this.createModel,
    this.saveModel,
    this.statusModel,
  });

  @override
  Future<List<TripModel>> getTrips({required String companyId}) async {
    return [currentModel];
  }

  @override
  Future<TripModel> getTripById({
    required String companyId,
    required String id,
  }) async {
    events.add('get');
    lastGetByIdCompanyId = companyId;
    return currentModel;
  }

  @override
  Future<TripFormLookups> getTripFormLookups({required String companyId}) {
    throw UnimplementedError();
  }

  @override
  Future<TripModel> createTrip({required TripWriteData data}) async {
    events.add('create');
    return createModel ?? currentModel;
  }

  @override
  Future<TripModel> saveTrip({
    required String id,
    required TripWriteData data,
  }) async {
    events.add('save');
    return saveModel ?? currentModel;
  }

  @override
  Future<TripModel> updateTripStatus({
    required String companyId,
    required String id,
    required TripStatus newStatus,
  }) async {
    events.add('status');
    lastStatusCompanyId = companyId;
    return statusModel ?? currentModel;
  }

  @override
  Future<TripStatusHistoryModel> addTripStatusHistory({
    required String companyId,
    required String tripId,
    required TripStatus? oldStatus,
    required TripStatus newStatus,
    required String actorRole,
    String? notes,
  }) async {
    events.add('history');
    lastHistoryCompanyId = companyId;
    lastHistoryOldStatus = oldStatus;
    lastHistoryNewStatus = newStatus;
    lastHistoryActorRole = actorRole;
    lastHistoryNotes = notes;

    return TripStatusHistoryModel(
      id: 'history-1',
      companyId: companyId,
      tripId: tripId,
      oldStatus: oldStatus?.value,
      newStatus: newStatus.value,
      changedByRole: actorRole,
      notes: notes,
      changedAt: DateTime.utc(2026, 8, 19),
    );
  }

  @override
  Future<List<TripStatusHistoryModel>> getTripStatusHistory({
    required String companyId,
    required String tripId,
  }) async {
    return const [];
  }

  @override
  Future<bool> hasOpenTripForVehicle({
    required String companyId,
    String? tractorHeadId,
    String? trailerId,
    String? excludingTripId,
  }) async {
    return false;
  }
}

class _FakeAuditLogRepository implements AuditLogRepository {
  final List<String> events;
  final Result<void> createResult;
  AuditLogWriteData? lastData;

  _FakeAuditLogRepository({
    required this.events,
    this.createResult = const Success<void>(null),
  });

  @override
  Future<Result<void>> createAuditLog({required AuditLogWriteData data}) async {
    lastData = data;
    events.add('audit:${data.description}');
    return createResult;
  }

  @override
  Future<Result<List<AuditLog>>> getEntityAuditLogs({
    required String companyId,
    required AuditModule module,
    required AuditEntityType entityType,
    required String entityId,
  }) {
    throw UnimplementedError();
  }
}
