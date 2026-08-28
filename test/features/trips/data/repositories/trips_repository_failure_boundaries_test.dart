import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/core/utils/result.dart';
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
  group('TripsRepository failure boundaries', () {
    test('forwards company scope for read operations', () async {
      final remoteDataSource = _FakeTripsRemoteDataSource();
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

    test(
      'sanitizes Postgrest read failures and preserves company forwarding',
      () async {
        final remoteDataSource = _FakeTripsRemoteDataSource(
          errors: const {
            _TripDataOperation.list: PostgrestException(
              message: 'permission denied',
              code: '42501',
              details: 'sensitive details',
              hint: 'sensitive hint',
            ),
          },
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

    test('sanitizes create persistence failure and stops before history', () async {
      final events = <String>[];
      final remoteDataSource = _FakeTripsRemoteDataSource(
        events: events,
        errors: const {
          _TripDataOperation.create: PostgrestException(
            message: 'insert failed',
            code: '23503',
            details: 'sensitive details',
            hint: 'sensitive hint',
          ),
        },
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
        events: events,
        errors: const {
          _TripDataOperation.history: PostgrestException(
            message: 'history insert failed',
            code: '42501',
          ),
        },
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

    test('sanitizes save persistence failure and does not audit', () async {
      final events = <String>[];
      final remoteDataSource = _FakeTripsRemoteDataSource(
        currentModel: _oldTripModel,
        events: events,
        errors: const {
          _TripDataOperation.save: PostgrestException(
            message: 'update failed',
            code: '42501',
          ),
        },
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

      expect(result, isA<FailureResult<TripEntity>>());
      expect(result.failureOrNull, isA<ServerFailure>());
      expect(result.failureOrNull?.code, FailureCodes.serverError);
      expect(result.failureOrNull?.message, isNull);
      expect(events, ['get', 'save']);
      expect(remoteDataSource.lastGetByIdCompanyId, _companyId);
      expect(remoteDataSource.lastGetByIdId, _tripId);
      expect(auditRepository.lastData, isNull);
    });

    test('sanitizes status persistence failure before history and audit', () async {
      final events = <String>[];
      final remoteDataSource = _FakeTripsRemoteDataSource(
        currentModel: _oldTripModel,
        events: events,
        errors: const {
          _TripDataOperation.status: PostgrestException(
            message: 'status update failed',
            code: '42501',
          ),
        },
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
      expect(result.failureOrNull, isA<ServerFailure>());
      expect(result.failureOrNull?.code, FailureCodes.serverError);
      expect(result.failureOrNull?.message, isNull);
      expect(events, ['get', 'status']);
      expect(auditRepository.lastData, isNull);
    });

    test('sanitizes status history runtime failure and does not audit', () async {
      final events = <String>[];
      final remoteDataSource = _FakeTripsRemoteDataSource(
        currentModel: _oldTripModel,
        statusModel: _loadedTripModel,
        events: events,
        errors: {
          _TripDataOperation.history: Exception('history runtime detail'),
        },
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

    test('preserves unknown stored status fallback behavior', () async {
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

      expect(result, isA<Success<TripEntity>>());
      expect(remoteDataSource.lastHistoryOldStatus, TripStatus.created);
      expect(events, ['get', 'status', 'history', 'audit:trip_status_changed']);
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
      auditRepository ?? _FakeAuditLogRepository(),
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

enum _TripDataOperation {
  list,
  get,
  lookups,
  create,
  save,
  status,
  history,
  historyList,
  openTrip,
}

class _FakeTripsRemoteDataSource implements TripsRemoteDataSource {
  final TripModel currentModel;
  final TripModel? createModel;
  final TripModel? saveModel;
  final TripModel? statusModel;
  final List<TripModel>? listModels;
  final List<String> events;
  final Map<_TripDataOperation, Object> errors;

  String? lastListCompanyId;
  String? lastGetByIdCompanyId;
  String? lastGetByIdId;
  String? lastLookupsCompanyId;
  String? lastStatusCompanyId;
  String? lastHistoryCompanyId;
  TripStatus? lastHistoryOldStatus;
  String? lastHistoryListCompanyId;
  String? lastHistoryListTripId;
  String? lastOpenTripCompanyId;
  String? lastOpenTripTractorHeadId;
  String? lastOpenTripTrailerId;
  String? lastOpenTripExcludingTripId;

  _FakeTripsRemoteDataSource({
    this.currentModel = _createdTripModel,
    this.createModel,
    this.saveModel,
    this.statusModel,
    this.listModels,
    List<String>? events,
    this.errors = const {},
  }) : events = events ?? <String>[];

  void _throwIfNeeded(_TripDataOperation operation) {
    final error = errors[operation];
    if (error != null) throw error;
  }

  @override
  Future<List<TripModel>> getTrips({required String companyId}) async {
    events.add('list');
    lastListCompanyId = companyId;
    _throwIfNeeded(_TripDataOperation.list);
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
    _throwIfNeeded(_TripDataOperation.get);
    return currentModel;
  }

  @override
  Future<TripFormLookups> getTripFormLookups({required String companyId}) async {
    events.add('lookups');
    lastLookupsCompanyId = companyId;
    _throwIfNeeded(_TripDataOperation.lookups);
    return _emptyLookups;
  }

  @override
  Future<TripModel> createTrip({required TripWriteData data}) async {
    events.add('create');
    _throwIfNeeded(_TripDataOperation.create);
    return createModel ?? currentModel;
  }

  @override
  Future<TripModel> saveTrip({
    required String id,
    required TripWriteData data,
  }) async {
    events.add('save');
    _throwIfNeeded(_TripDataOperation.save);
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
    _throwIfNeeded(_TripDataOperation.status);
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
    _throwIfNeeded(_TripDataOperation.history);

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
    _throwIfNeeded(_TripDataOperation.historyList);
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
    _throwIfNeeded(_TripDataOperation.openTrip);
    return false;
  }
}

class _FakeAuditLogRepository implements AuditLogRepository {
  final List<String> events;
  AuditLogWriteData? lastData;

  _FakeAuditLogRepository({List<String>? events})
    : events = events ?? <String>[];

  @override
  Future<Result<void>> createAuditLog({required AuditLogWriteData data}) async {
    lastData = data;
    events.add('audit:${data.description}');
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
