import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/core/documents/domain/entities/business_document_access.dart';
import 'package:horus_system/core/documents/domain/entities/business_document_file.dart';
import 'package:horus_system/core/domain/value_objects/currency_configuration.dart';
import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/core/usecases/convert_instants_to_business_local_date_times_usecase.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/audit/domain/entities/audit_entity_type.dart';
import 'package:horus_system/features/audit/domain/entities/audit_log.dart';
import 'package:horus_system/features/audit/domain/entities/audit_log_write_data.dart';
import 'package:horus_system/features/audit/domain/entities/audit_module.dart';
import 'package:horus_system/features/audit/domain/repositories/audit_log_repository.dart';
import 'package:horus_system/features/audit/domain/usecases/get_entity_audit_logs_usecase.dart';
import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/entities/current_company_context.dart';
import 'package:horus_system/features/expense_types/domain/entities/expense_type.dart';
import 'package:horus_system/features/expense_types/domain/repositories/expense_types_repository.dart';
import 'package:horus_system/features/expense_types/domain/usecases/get_expense_type_catalog_usecase.dart';
import 'package:horus_system/features/expense_types/domain/usecases/get_ledger_eligible_expense_types_usecase.dart';
import 'package:horus_system/features/expenses/domain/entities/expense_ledger_entry.dart';
import 'package:horus_system/features/expenses/domain/entities/expense_ledger_write_data.dart';
import 'package:horus_system/features/expenses/domain/repositories/expense_ledger_repository.dart';
import 'package:horus_system/features/expenses/domain/usecases/create_expense_ledger_entry_usecase.dart';
import 'package:horus_system/features/expenses/domain/usecases/create_trip_expense_usecase.dart';
import 'package:horus_system/features/expenses/domain/usecases/get_trip_expense_ledger_entries_usecase.dart';
import 'package:horus_system/features/expenses/domain/usecases/void_expense_ledger_entry_usecase.dart';
import 'package:horus_system/features/trips/domain/entities/trip_document.dart';
import 'package:horus_system/features/trips/domain/entities/trip_document_kind.dart';
import 'package:horus_system/features/trips/domain/entities/trip_entity.dart';
import 'package:horus_system/features/trips/domain/entities/trip_form_lookups.dart';
import 'package:horus_system/features/trips/domain/entities/trip_lookup_option.dart';
import 'package:horus_system/features/trips/domain/entities/trip_route_lookup_option.dart';
import 'package:horus_system/features/trips/domain/entities/trip_status.dart';
import 'package:horus_system/features/trips/domain/entities/trip_status_history.dart';
import 'package:horus_system/features/trips/domain/entities/trip_write_data.dart';
import 'package:horus_system/features/trips/domain/repositories/trip_documents_repository.dart';
import 'package:horus_system/features/trips/domain/repositories/trips_repository.dart';
import 'package:horus_system/features/trips/domain/usecases/trips_usecases.dart';
import 'package:horus_system/features/trips/presentation/cubit/trips_cubit.dart';
import 'package:horus_system/features/trips/presentation/cubit/trips_state.dart';
import 'package:horus_system/features/trips/presentation/models/trip_mutation_result.dart';

import '../../../../helpers/fake_business_time_zone_converter.dart';

void main() {
  group('PC-10 TripsCubit operational hardening', () {
    test(
      'ignores an old company load after a newer company load wins',
      () async {
        final repository = _FakeTripsRepository();
        final oldLoad = Completer<Result<List<TripEntity>>>();
        repository.pendingLoads['company-a'] = oldLoad;
        repository.tripsByCompany['company-b'] = const [_tripB];

        final cubit = _buildCubit(repository);
        addTearDown(cubit.close);

        final oldRequest = cubit.loadTrips(_contextA);
        await Future<void>.delayed(Duration.zero);

        await cubit.loadTrips(_contextB);

        final loadedB = cubit.state as TripsLoaded;
        expect(loadedB.currentCompanyContext.companyId, 'company-b');
        expect(loadedB.allTrips, const [_tripB]);

        oldLoad.complete(const Success([_tripA]));
        await oldRequest;

        final stillLoadedB = cubit.state as TripsLoaded;
        expect(stillLoadedB.currentCompanyContext.companyId, 'company-b');
        expect(stillLoadedB.allTrips, const [_tripB]);
      },
    );

    test(
      'failed create preserves loaded state and retry succeeds once',
      () async {
        final repository = _FakeTripsRepository()
          ..tripsByCompany['company-a'] = const [_tripA]
          ..createResults.add(
            const FailureResult<TripEntity>(
              ServerFailure(code: FailureCodes.serverError),
            ),
          )
          ..createResults.add(const Success(_tripCreated));

        final cubit = _buildCubit(repository);
        addTearDown(cubit.close);
        await cubit.loadTrips(_contextA);

        final firstResult = await cubit.saveTrip(
          customerId: 'customer-new',
          routeId: 'route-new',
        );

        expect(firstResult, isA<TripMutationFailed>());
        final failedState = cubit.state as TripsLoaded;
        expect(failedState.allTrips, const [_tripA]);
        expect(failedState.isTripSaving, isFalse);
        expect(failedState.tripSaveFailure?.code, FailureCodes.serverError);

        final retryResult = await cubit.saveTrip(
          customerId: 'customer-new',
          routeId: 'route-new',
        );

        expect(retryResult, isA<TripMutationSucceeded>());
        final retryState = cubit.state as TripsLoaded;
        expect(repository.createCalls, 2);
        expect(
          retryState.allTrips.map((trip) => trip.id),
          contains('trip-new'),
        );
        expect(retryState.tripSaveFailure, isNull);
      },
    );

    test(
      'duplicate save is ignored while the first mutation is pending',
      () async {
        final repository = _FakeTripsRepository()
          ..tripsByCompany['company-a'] = const [_tripA];
        final pendingCreate = Completer<Result<TripEntity>>();
        repository.pendingCreate = pendingCreate;

        final cubit = _buildCubit(repository);
        addTearDown(cubit.close);
        await cubit.loadTrips(_contextA);

        final first = cubit.saveTrip(
          customerId: 'customer-new',
          routeId: 'route-new',
        );
        await Future<void>.delayed(Duration.zero);

        final second = await cubit.saveTrip(
          customerId: 'customer-new',
          routeId: 'route-new',
        );

        expect(second, isA<TripMutationIgnored>());
        expect(repository.createCalls, 1);
        expect((cubit.state as TripsLoaded).isTripSaving, isTrue);

        pendingCreate.complete(const Success(_tripCreated));
        expect(await first, isA<TripMutationSucceeded>());
        expect(repository.createCalls, 1);
        expect((cubit.state as TripsLoaded).isTripSaving, isFalse);
      },
    );

    test(
      'stale mutation completion cannot overwrite a new company context',
      () async {
        final repository = _FakeTripsRepository()
          ..tripsByCompany['company-a'] = const [_tripA]
          ..tripsByCompany['company-b'] = const [_tripB];
        final pendingCreate = Completer<Result<TripEntity>>();
        repository.pendingCreate = pendingCreate;

        final cubit = _buildCubit(repository);
        addTearDown(cubit.close);
        await cubit.loadTrips(_contextA);

        final pendingMutation = cubit.saveTrip(
          customerId: 'customer-new',
          routeId: 'route-new',
        );
        await Future<void>.delayed(Duration.zero);

        await cubit.loadTrips(_contextB);
        pendingCreate.complete(const Success(_tripCreated));

        expect(await pendingMutation, isA<TripMutationIgnored>());
        final current = cubit.state as TripsLoaded;
        expect(current.currentCompanyContext.companyId, 'company-b');
        expect(current.allTrips, const [_tripB]);
      },
    );

    test(
      'status failure preserves loaded trip and retry clears scoped failure',
      () async {
        final repository = _FakeTripsRepository()
          ..tripsByCompany['company-a'] = const [_tripA]
          ..detailsById['trip-a'] = _tripA
          ..statusResults.add(
            const FailureResult<TripEntity>(
              ServerFailure(code: FailureCodes.serverError),
            ),
          )
          ..statusResults.add(const Success(_tripAssigned));

        final cubit = _buildCubit(repository);
        addTearDown(cubit.close);
        await cubit.loadTrips(_contextA);

        final firstResult = await cubit.updateTripStatus(
          trip: _tripA,
          newStatus: TripStatus.assigned,
        );

        expect(firstResult, isA<TripMutationFailed>());
        final failedState = cubit.state as TripsLoaded;
        expect(failedState.allTrips.single.status, TripStatus.created);
        expect(
          failedState.statusChangeFailureFor('trip-a')?.code,
          FailureCodes.serverError,
        );
        expect(failedState.isStatusChanging('trip-a'), isFalse);

        final retryResult = await cubit.updateTripStatus(
          trip: _tripA,
          newStatus: TripStatus.assigned,
        );

        expect(retryResult, isA<TripMutationSucceeded>());
        final retryState = cubit.state as TripsLoaded;
        expect(repository.statusCalls, 2);
        expect(retryState.allTrips.single.status, TripStatus.assigned);
        expect(retryState.statusChangeFailureFor('trip-a'), isNull);
      },
    );
  });
}

const _contextA = CurrentCompanyContext(
  company: Company(
    id: 'company-a',
    name: 'Company A',
    baseCurrencyCode: 'AED',
    baseCurrencyFractionDigits: 2,
    businessTimezone: 'UTC',
  ),
  role: CompanyRole.operations,
);

const _contextB = CurrentCompanyContext(
  company: Company(
    id: 'company-b',
    name: 'Company B',
    baseCurrencyCode: 'AED',
    baseCurrencyFractionDigits: 2,
    businessTimezone: 'UTC',
  ),
  role: CompanyRole.operations,
);

const _tripA = TripEntity(
  id: 'trip-a',
  companyId: 'company-a',
  customerId: 'customer-a',
  routeId: 'route-a',
  status: TripStatus.created,
);

const _tripB = TripEntity(
  id: 'trip-b',
  companyId: 'company-b',
  customerId: 'customer-b',
  routeId: 'route-b',
  status: TripStatus.created,
);

const _tripCreated = TripEntity(
  id: 'trip-new',
  companyId: 'company-a',
  customerId: 'customer-new',
  routeId: 'route-new',
  status: TripStatus.created,
);

const _tripAssigned = TripEntity(
  id: 'trip-a',
  companyId: 'company-a',
  customerId: 'customer-a',
  routeId: 'route-a',
  status: TripStatus.assigned,
);

TripsCubit _buildCubit(_FakeTripsRepository tripsRepository) {
  const converter = FakeBusinessTimeZoneConverter();
  final expenseRepository = _NoopExpenseLedgerRepository();
  final expenseTypesRepository = _NoopExpenseTypesRepository();
  final documentsRepository = _NoopTripDocumentsRepository();

  return TripsCubit(
    getTripsUseCase: GetTripsUseCase(tripsRepository),
    getTripDetailsUseCase: GetTripDetailsUseCase(tripsRepository),
    getTripFormLookupsUseCase: GetTripFormLookupsUseCase(tripsRepository),
    createTripUseCase: CreateTripUseCase(tripsRepository),
    saveTripUseCase: SaveTripUseCase(tripsRepository),
    updateTripStatusUseCase: UpdateTripStatusUseCase(
      tripsRepository,
      documentsRepository,
    ),
    getTripStatusHistoryUseCase: GetTripStatusHistoryUseCase(tripsRepository),
    getTripDocumentsUseCase: GetTripDocumentsUseCase(documentsRepository),
    uploadTripDocumentUseCase: UploadTripDocumentUseCase(documentsRepository),
    getTripDocumentAccessUseCase: GetTripDocumentAccessUseCase(
      documentsRepository,
    ),
    downloadTripDocumentUseCase: DownloadTripDocumentUseCase(
      documentsRepository,
    ),
    removeTripDocumentUseCase: RemoveTripDocumentUseCase(documentsRepository),
    replaceTripDocumentUseCase: ReplaceTripDocumentUseCase(documentsRepository),
    calculateTripNetProfitUseCase: const CalculateTripNetProfitUseCase(),
    getTripBusinessLocalTimestampsUseCase:
        const GetTripBusinessLocalTimestampsUseCase(converter),
    resolveTripBusinessLocalTimestampsUseCase:
        const ResolveTripBusinessLocalTimestampsUseCase(converter),
    convertInstantsToBusinessLocalDateTimesUseCase:
        const ConvertInstantsToBusinessLocalDateTimesUseCase(converter),
    getTripAuditLogsUseCase: GetEntityAuditLogsUseCase(
      _NoopAuditLogRepository(),
    ),
    getTripExpenseLedgerEntriesUseCase: GetTripExpenseLedgerEntriesUseCase(
      expenseRepository,
    ),
    getExpenseTypeCatalogUseCase: GetExpenseTypeCatalogUseCase(
      expenseTypesRepository,
    ),
    getLedgerEligibleExpenseTypesUseCase: GetLedgerEligibleExpenseTypesUseCase(
      expenseTypesRepository,
    ),
    createTripExpenseUseCase: CreateTripExpenseUseCase(
      CreateExpenseLedgerEntryUseCase(expenseRepository),
    ),
    voidExpenseLedgerEntryUseCase: VoidExpenseLedgerEntryUseCase(
      expenseRepository,
    ),
  );
}

final class _FakeTripsRepository implements TripsRepository {
  final Map<String, List<TripEntity>> tripsByCompany = {};
  final Map<String, Completer<Result<List<TripEntity>>>> pendingLoads = {};
  final Map<String, TripEntity> detailsById = {};
  final Queue<Result<TripEntity>> createResults = Queue();
  final Queue<Result<TripEntity>> saveResults = Queue();
  final Queue<Result<TripEntity>> statusResults = Queue();
  Completer<Result<TripEntity>>? pendingCreate;
  int createCalls = 0;
  int statusCalls = 0;

  @override
  Future<Result<List<TripEntity>>> getTrips({
    required String companyId,
    required CurrencyConfiguration? financialConfiguration,
  }) {
    final pending = pendingLoads[companyId];
    if (pending != null) return pending.future;
    return Future.value(Success(tripsByCompany[companyId] ?? const []));
  }

  @override
  Future<Result<TripEntity>> getTripDetails({
    required String companyId,
    required String id,
    required CurrencyConfiguration? financialConfiguration,
  }) {
    var trip = detailsById[id];
    if (trip == null) {
      for (final candidate
          in tripsByCompany[companyId] ?? const <TripEntity>[]) {
        if (candidate.id == id) {
          trip = candidate;
          break;
        }
      }
    }
    if (trip == null) {
      return Future.value(
        const FailureResult(NotFoundFailure(code: 'test_trip_not_found')),
      );
    }
    return Future.value(Success(trip));
  }

  @override
  Future<Result<TripFormLookups>> getTripFormLookups({
    required String companyId,
    required CurrencyConfiguration? financialConfiguration,
  }) {
    return Future.value(
      const Success(
        TripFormLookups(
          customers: [TripLookupOption(id: 'customer', label: 'Customer')],
          routes: [TripRouteLookupOption(id: 'route', label: 'Route')],
          drivers: [],
          tractorHeads: [],
          trailers: [],
        ),
      ),
    );
  }

  @override
  Future<Result<TripEntity>> createTrip({
    required TripWriteData data,
    required CurrencyConfiguration? financialConfiguration,
  }) {
    createCalls++;
    final pending = pendingCreate;
    if (pending != null) return pending.future;
    if (createResults.isNotEmpty) {
      return Future.value(createResults.removeFirst());
    }
    return Future.value(
      Success(
        TripEntity(
          id: 'trip-created-$createCalls',
          companyId: data.companyId,
          customerId: data.customerId,
          routeId: data.routeId,
          status: TripStatus.created,
        ),
      ),
    );
  }

  @override
  Future<Result<TripEntity>> saveTrip({
    required String id,
    required TripWriteData data,
    required CurrencyConfiguration? financialConfiguration,
  }) {
    if (saveResults.isNotEmpty) {
      return Future.value(saveResults.removeFirst());
    }
    return Future.value(
      Success(
        TripEntity(
          id: id,
          companyId: data.companyId,
          customerId: data.customerId,
          routeId: data.routeId,
          status: detailsById[id]?.status ?? TripStatus.created,
        ),
      ),
    );
  }

  @override
  Future<Result<TripEntity>> updateTripStatus({
    required String companyId,
    required String id,
    required TripStatus newStatus,
    required CurrencyConfiguration? financialConfiguration,
    String? notes,
  }) {
    statusCalls++;
    if (statusResults.isNotEmpty) {
      return Future.value(statusResults.removeFirst());
    }
    final current = detailsById[id]!;
    return Future.value(
      Success(
        TripEntity(
          id: current.id,
          companyId: current.companyId,
          customerId: current.customerId,
          routeId: current.routeId,
          status: newStatus,
        ),
      ),
    );
  }

  @override
  Future<Result<List<TripStatusHistory>>> getTripStatusHistory({
    required String companyId,
    required String tripId,
  }) {
    return Future.value(const Success([]));
  }

  @override
  Future<Result<bool>> hasOpenTripForVehicle({
    required String companyId,
    String? tractorHeadId,
    String? trailerId,
    String? excludingTripId,
  }) {
    return Future.value(const Success(false));
  }
}

final class _NoopAuditLogRepository implements AuditLogRepository {
  @override
  Future<Result<void>> createAuditLog({required AuditLogWriteData data}) {
    return Future.value(const Success<void>(null));
  }

  @override
  Future<Result<List<AuditLog>>> getEntityAuditLogs({
    required String companyId,
    required AuditModule module,
    required AuditEntityType entityType,
    required String entityId,
  }) {
    return Future.value(const Success([]));
  }
}

final class _NoopExpenseLedgerRepository implements ExpenseLedgerRepository {
  @override
  Future<Result<List<ExpenseLedgerEntry>>> getEntries({
    required String companyId,
    bool includeVoided = false,
  }) {
    return Future.value(const Success([]));
  }

  @override
  Future<Result<List<ExpenseLedgerEntry>>> getEntriesForTrip({
    required String companyId,
    required String tripId,
    bool includeVoided = false,
  }) {
    return Future.value(const Success([]));
  }

  @override
  Future<Result<ExpenseLedgerEntry>> createEntry(ExpenseLedgerWriteData data) {
    throw UnimplementedError();
  }

  @override
  Future<Result<ExpenseLedgerEntry>> voidEntry({
    required String companyId,
    required String expenseId,
    String? reason,
  }) {
    throw UnimplementedError();
  }
}

final class _NoopExpenseTypesRepository implements ExpenseTypesRepository {
  @override
  Future<Result<List<ExpenseType>>> getExpenseTypes({
    required String companyId,
  }) {
    return Future.value(const Success([]));
  }

  @override
  Future<Result<List<ExpenseType>>> getActiveExpenseTypes({
    required String companyId,
  }) {
    return Future.value(const Success([]));
  }

  @override
  Future<Result<List<ExpenseType>>> getLedgerEligibleExpenseTypes({
    required String companyId,
  }) {
    return Future.value(const Success([]));
  }
}

final class _NoopTripDocumentsRepository implements TripDocumentsRepository {
  @override
  Future<Result<List<TripDocument>>> getActiveDocuments({
    required String companyId,
    required String tripId,
  }) {
    return Future.value(const Success([]));
  }

  @override
  Future<Result<TripDocument>> upload({
    required String companyId,
    required String tripId,
    required TripDocumentKind kind,
    required BusinessDocumentFile document,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Result<BusinessDocumentAccess>> createTemporaryAccess({
    required String companyId,
    required String tripId,
    required String documentId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Result<Uint8List>> download({
    required String companyId,
    required String tripId,
    required String documentId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Result<TripDocument>> replace({
    required String companyId,
    required String tripId,
    required String documentId,
    required BusinessDocumentFile document,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Result<void>> remove({
    required String companyId,
    required String tripId,
    required String documentId,
  }) {
    throw UnimplementedError();
  }
}
