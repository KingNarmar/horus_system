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
import 'package:horus_system/features/trips/domain/entities/trip_form_lookups.dart';
import 'package:horus_system/features/trips/domain/entities/trip_status.dart';
import 'package:horus_system/features/trips/domain/entities/trip_write_data.dart';

const testCompanyId = 'company-1';
const testTripId = 'trip-1';

const testTripWriteData = TripWriteData(
  companyId: testCompanyId,
  customerId: 'customer-1',
  routeId: 'route-1',
  driverId: 'driver-1',
  tractorHeadId: 'tractor-1',
  trailerId: 'trailer-1',
  loadingOrderNumber: 'LO-001',
  waybillNumber: 'WB-NEW',
  notes: 'Trip notes',
);

const testCreatedTripModel = TripModel(
  id: testTripId,
  companyId: testCompanyId,
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

const testOldTripModel = TripModel(
  id: testTripId,
  companyId: testCompanyId,
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

const testUnknownStatusTripModel = TripModel(
  id: testTripId,
  companyId: testCompanyId,
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

const testLoadedTripModel = TripModel(
  id: testTripId,
  companyId: testCompanyId,
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

const testEmptyLookups = TripFormLookups(
  customers: [],
  routes: [],
  drivers: [],
  tractorHeads: [],
  trailers: [],
);

TripsRepositoryImpl createTripsRepository(
  TripsRemoteDataSource remoteDataSource, {
  FakeTripAuditLogRepository? auditRepository,
}) {
  return TripsRepositoryImpl(
    remoteDataSource: remoteDataSource,
    createAuditLogUseCase: CreateAuditLogUseCase(
      auditRepository ?? FakeTripAuditLogRepository(),
    ),
  );
}

class ThrowingTripModel extends TripModel {
  const ThrowingTripModel()
    : super(
        id: 'trip-broken',
        companyId: testCompanyId,
        customerId: 'customer-1',
        routeId: 'route-1',
        status: 'created',
      );

  @override
  String get status => throw StateError('mapping internal detail');
}

enum TripDataOperation {
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

class FakeTripsRemoteDataSource implements TripsRemoteDataSource {
  final TripModel currentModel;
  final TripModel? statusModel;
  final List<TripModel>? listModels;
  final List<String> events;
  final Map<TripDataOperation, Object> errors;

  String? lastListCompanyId;
  String? lastGetByIdCompanyId;
  String? lastGetByIdId;
  String? lastLookupsCompanyId;
  String? lastHistoryListCompanyId;
  String? lastHistoryListTripId;
  String? lastOpenTripCompanyId;
  String? lastOpenTripTractorHeadId;
  String? lastOpenTripTrailerId;
  String? lastOpenTripExcludingTripId;
  TripStatus? lastHistoryOldStatus;

  FakeTripsRemoteDataSource({
    this.currentModel = testCreatedTripModel,
    this.statusModel,
    this.listModels,
    List<String>? events,
    this.errors = const {},
  }) : events = events ?? <String>[];

  void _throwIfNeeded(TripDataOperation operation) {
    final error = errors[operation];
    if (error != null) throw error;
  }

  @override
  Future<List<TripModel>> getTrips({required String companyId}) async {
    events.add('list');
    lastListCompanyId = companyId;
    _throwIfNeeded(TripDataOperation.list);
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
    _throwIfNeeded(TripDataOperation.get);
    return currentModel;
  }

  @override
  Future<TripFormLookups> getTripFormLookups({required String companyId}) async {
    events.add('lookups');
    lastLookupsCompanyId = companyId;
    _throwIfNeeded(TripDataOperation.lookups);
    return testEmptyLookups;
  }

  @override
  Future<TripModel> createTrip({required TripWriteData data}) async {
    events.add('create');
    _throwIfNeeded(TripDataOperation.create);
    return currentModel;
  }

  @override
  Future<TripModel> saveTrip({
    required String id,
    required TripWriteData data,
  }) async {
    events.add('save');
    _throwIfNeeded(TripDataOperation.save);
    return currentModel;
  }

  @override
  Future<TripModel> updateTripStatus({
    required String companyId,
    required String id,
    required TripStatus newStatus,
  }) async {
    events.add('status');
    _throwIfNeeded(TripDataOperation.status);
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
    lastHistoryOldStatus = oldStatus;
    _throwIfNeeded(TripDataOperation.history);

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
    _throwIfNeeded(TripDataOperation.historyList);
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
    _throwIfNeeded(TripDataOperation.openTrip);
    return false;
  }
}

class FakeTripAuditLogRepository implements AuditLogRepository {
  final List<String> events;
  AuditLogWriteData? lastData;

  FakeTripAuditLogRepository({List<String>? events})
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
