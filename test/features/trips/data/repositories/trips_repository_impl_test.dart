import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/errors/failure_codes.dart';
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
import 'package:horus_system/features/trips/domain/entities/trip_entity.dart';
import 'package:horus_system/features/trips/domain/entities/trip_form_lookups.dart';
import 'package:horus_system/features/trips/domain/entities/trip_status.dart';
import 'package:horus_system/features/trips/domain/entities/trip_write_data.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;
import 'package:test/test.dart';

void main() {
  group('TripsRepositoryImpl', () {
    test('forwards company scope for read operations', () async {
      final remoteDataSource = _FakeTripsRemoteDataSource(
        currentModel: _createdTripModel,
        events: [],
      );
      final repository = _repository(remoteDataSource);

      final listResult = await repository.getTrips(companyId: _companyId);
      final detailsResult = await repository.getTripDetails(
        companyId: _companyId,
        id: _tripId,
      );
      final lookupsResult = await repository.getTripFormLookups(
        companyId: _companyId,
      );
      final historyResult = await repository.getTripStatusHistory(
        companyId: _companyId,
        tripId: _tripId,
      );
      final openTripResult = await repository.hasOpenTripForVehicle(
        companyId: _companyId,
        tractorHeadId: 'tractor-1',
        trailerId: 'trailer-1',
        excludingTripId: _tripId,
      );

      expect(listResult, isA<Success<List<TripEntity>>>());
      expect(detailsResult, isA<Success<TripEntity>>());
      expect(lookupsResult, isA<Success<TripFormLookups>>());
      expect(historyResult, isA<Success>());
      expect(openTripResult, isA<Success<bool>>());
      expect(remoteDataSource.lastListCompanyId, _companyId);
      expect(remoteDataSource.lastGetByIdCompanyId, _companyId);
      expect(remoteDataSource.lastGetByIdId, _tripId);
      expect(remoteDataSource.lastLookupsCompanyId, _companyId);
      expect(remoteDataSource.lastHistoryListCompanyId, _companyId);
      expect(remoteDataSource.lastHistoryListTripId, _tripId);
      expect(remoteDataSource.lastOpenTripCompanyId, _companyId);
      expect(remoteDataSource.lastOpenTripTractorHeadId, 'tractor-1');
      expect(remoteDataSource.lastOpenTripTrailerId, 'trailer-1');
      expect(remoteDataSource.lastOpenTripExcludingTripId, _tripId);
    });

    test('preserves create, initial history, then audit ordering', () async {
      final events = <String>[];
      final remoteDataSource = _FakeTripsRemoteDataSource(
        currentModel: _createdTripModel,
        createModel: _createdTripModel,
        events: events,
      );
      final auditRepository = _FakeAuditLogRepository(events: events);
      final repository = _repository(
        remoteDataSource,
        auditRepository: auditRepository,
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
      final repository = _repository(
        remoteDataSource,
        auditRepository: auditRepository,
      );

      final result = await repository.saveTrip(
        id: _tripId,
        data: _writeData,
        actorRole: 'operations',
      );

      expect(result, isA<Success>());
      expect(events, ['get', 'save', 'audit:trip_updated']);
      expect(remoteDataSource.lastGetByIdCompanyId, _companyId);
      expect(remoteDataSource.lastGetByIdId, _tripId);

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
      final repository = _repository(
        remoteDataSource,
        auditRepository: auditRepository,
      );

      final result = await repository.updateTripStatus(
        companyId: _companyId,
        id: _tripId,
        newStatus: TripStatus.loaded,
        actorRole: 'operations',
        notes: 'Loaded at yard',
      );

      expect(result, isA<Success>());
      expect(events, ['get', 'status', 'history', 'audit:trip_status_changed']);
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

    test('preserves status fallback behavior for unknown stored status', () async {
      final events = <String>[];
      final remoteDataSource = _FakeTripsRemoteDataSource(
        currentModel: _unknownStatusTripModel,
        statusModel: _loadedTripModel,
        events: events,
      );
      final auditRepository = _FakeAuditLogRepository(events: events);
      final repository = _repository(
        remoteDataSource,
        auditRepository: auditRepository,
      );

      final result = await repository.updateTripStatus(
        companyId: _companyId,
        id: _tripId,
        newStatus: TripStatus.loaded,
        actorRole: 'operations',
      );

      expect(result, isA<Success>());
      expect(remoteDataSource.lastHistoryOldStatus, TripStatus.created);
      expect(events, ['get', 'status', 'history', 'audit:trip_status_changed']);
    });

    test(
      'sanitizes Postgrest read failures and preserves company forwarding',
      () async {
        final remoteDataSource = _FakeTripsRemoteDataSource(
          currentModel: _createdTripModel,
          events: [],
          listError: const PostgrestException(
            message: 'permission denied',
            code: '42501',
            details: 'sensitive details',
            hint: 'sensitive hint',
          ),
        );
        final repository = _repository(remoteDataSource);

        final result = await repository.getTrips(companyId: _companyId);

        expect(result, isA<FailureResult<List<TripEntity>>>());
        expect(result.failureOrNull, isA<ServerFailure>());
        expect(result.failureOrNull?.code, FailureCodes.serverError);
        expect(result.failureOrNull?.message, isNull);
        expect(remoteDataSource.lastListCompanyId, _companyId);
      },
    );

    test(
      'sanitizes model-to-entity mapping failures inside repository guard',
      () async {
        final remoteDataSource = _FakeTripsRemoteDataSource(
          currentModel: _createdTripModel,
          events: [],
          listModels: const [_ThrowingTripModel()],
        );
        final repository = _repository(remoteDataSource);

        final result = await repository.getTrips(companyId: _companyId);

        expect(result, isA<FailureResult<List<TripEntity>>>());
        expect(result.failureOrNull, isA<UnexpectedFailure>());
        expect(result.failureOrNull?.code, FailureCodes.unexpectedError);
        expect(result.failureOrNull?.message, isNull);
        expect(remoteDataSource.lastListCompanyId, _companyId);
      },
    );

    test('sanitizes create persistence failure and does not continue', () async {
      final events = <String>[];
      final remoteDataSource = _FakeTripsRemoteDataSource(
        currentModel: _createdTripModel,
        events: events,
        createError: const PostgrestException(
          message: 'insert failed',
          code: '23503',
          details: 'sensitive details',
          hint: 'sensitive hint',
        ),
      );
      final auditRepository = _FakeAuditLogRepository(events: events);
      final repository = _repository(
        remoteDataSource,
        auditRepository: auditRepository,
      );

      final result = await repository.createTrip(
        data: _writeData,
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
      final remoteDataSource = _FakeTripsRemoteDataSource(
        currentModel: _createdTripModel,
        createModel: _createdTripModel,
        events: events,
        historyError: const PostgrestException(
          message: 'history insert failed',
          code: '42501',
        ),
      );
      final auditRepository = _FakeAuditLogRepository(events: events);
      final repository = _repository(
        remoteDataSource,
        auditRepository: auditRepository,
      );

      final result = await repository.createTrip(
        data: _writeData,
        actorRole: 'owner',
      );

      expect(result, isA<FailureResult<TripEntity>>());
      expect(result.failureOrNull, isA<ServerFailure>());
      expect(result.failureOrNull?.code, FailureCodes.serverError);
      expect(result.failureOrNull?.message, isNull);
      expect(events, ['create', 'history']);
      expect(auditRepository.lastData, isNull);
    });

    test('sanitizes status history failure and does not audit', () async {
      final events = <String>[];
      final remoteDataSource = _FakeTripsRemoteDataSource(
        currentModel: _oldTripModel,
        statusModel: _loadedTripModel,
        events: events,
        historyError: Exception('history runtime detail'),
      );
      final auditRepository = _FakeAuditLogRepository(events: events);
      final repository = _repository(
        remoteDataSource,
        auditRepository: auditRepository,
      );

      final result = await repository.updateTripStatus(
        companyId: _companyId,
        id: _tripId,
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
      final repository = _repository(
        remoteDataSource,
        auditRepository: auditRepository,
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

TripsRepositoryImpl _repository(
  TripsRemoteDataSource remoteDataSource, {
  _FakeAuditLogRepository? auditRepository,
}) {
  return TripsRepositoryImpl(
    remoteDataSource: remoteDataSource,
    createAuditLogUseCase: CreateAuditLogUseCase(
      auditRepository ?? _FakeAuditLogRepository(events: []),
    ),
  );
}

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

const _unknownStatusTripModel = TripModel(
  id: _tripId,
  companyId: _companyId,
  customerId: 'customer-1',
  routeId: 'route-1',
  driverId: 'driver-1',
  tractorHeadId: 'tractor-1',
  trailerId: 'trailer-1',
  status: 'legacy_unknown',
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

const _emptyLookups = TripFormLookups(
  customers: [],
  routes: [],
  drivers: [],
  tractorHeads: [],
  trailers: [],
);

class _ThrowingTripModel extends TripModel {
  const _ThrowingTripModel()
    : super(
        id: 'trip-broken',
        companyId: _companyId,
        customerId: 'customer-1',
        routeId: 'route-1',
        status: 'created',
      );

  @override
  String get status => throw StateError('mapping internal detail');
}

class _FakeTripsRemoteDataSource implements TripsRemoteDataSource {
  final TripModel currentModel;
  final TripModel? createModel;
  final TripModel? saveModel;
  final TripModel? statusModel;
  final List<String> events;
  final List<TripModel>? listModels;
  final Object? listError;
  final Object? getError;
  final Object? lookupsError;
  final Object? createError;
  final Object? saveError;
  final Object? statusError;
  final Object? historyError;
  final Object? historyListError;
  final Object? openTripError;

  String? lastListCompanyId;
  String? lastGetByIdCompanyId;
  String? lastGetByIdId;
  String? lastLookupsCompanyId;
  String? lastStatusCompanyId;
  String? lastHistoryCompanyId;
  TripStatus? lastHistoryOldStatus;
  TripStatus? lastHistoryNewStatus;
  String? lastHistoryActorRole;
  String? lastHistoryNotes;
  String? lastHistoryListCompanyId;
  String? lastHistoryListTripId;
  String? lastOpenTripCompanyId;
  String? lastOpenTripTractorHeadId;
  String? lastOpenTripTrailerId;
  String? lastOpenTripExcludingTripId;

  _FakeTripsRemoteDataSource({
    required this.currentModel,
    required this.events,
    this.createModel,
    this.saveModel,
    this.statusModel,
    this.listModels,
    this.listError,
    this.getError,
    this.lookupsError,
    this.createError,
    this.saveError,
    this.statusError,
    this.historyError,
    this.historyListError,
    this.openTripError,
  });

  @override
  Future<List<TripModel>> getTrips({required String companyId}) async {
    events.add('list');
    lastListCompanyId = companyId;
    if (listError != null) throw listError!;
    return listModels ?? [currentModel];
  }

  @override
  Future<TripModel> getTripById({
    required String companyId,
    required String id,
  }) async {
    events.add('get');
    lastGetByIdCompanyId = companyId;
    lastGetByIdId = id;
    if (getError != null) throw getError!;
    return currentModel;
  }

  @override
  Future<TripFormLookups> getTripFormLookups({required String companyId}) async {
    events.add('lookups');
    lastLookupsCompanyId = companyId;
    if (lookupsError != null) throw lookupsError!;
    return _emptyLookups;
  }

  @override
  Future<TripModel> createTrip({required TripWriteData data}) async {
    events.add('create');
    if (createError != null) throw createError!;
    return createModel ?? currentModel;
  }

  @override
  Future<TripModel> saveTrip({
    required String id,
    required TripWriteData data,
  }) async {
    events.add('save');
    if (saveError != null) throw saveError!;
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
    if (statusError != null) throw statusError!;
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
    if (historyError != null) throw historyError!;

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
    events.add('history_list');
    lastHistoryListCompanyId = companyId;
    lastHistoryListTripId = tripId;
    if (historyListError != null) throw historyListError!;
    return const [];
  }

  @override
  Future<bool> hasOpenTripForVehicle({
    required String companyId,
    String? tractorHeadId,
    String? trailerId,
    String? excludingTripId,
  }) async {
    events.add('open_trip');
    lastOpenTripCompanyId = companyId;
    lastOpenTripTractorHeadId = tractorHeadId;
    lastOpenTripTrailerId = trailerId;
    lastOpenTripExcludingTripId = excludingTripId;
    if (openTripError != null) throw openTripError!;
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
