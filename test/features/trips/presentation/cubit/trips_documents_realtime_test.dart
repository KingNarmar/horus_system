import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/core/documents/domain/entities/business_document_file.dart';
import 'package:horus_system/core/domain/services/company_business_date_provider.dart';
import 'package:horus_system/core/domain/value_objects/business_date.dart';
import 'package:horus_system/core/domain/value_objects/currency_code.dart';
import 'package:horus_system/core/domain/value_objects/money.dart';
import 'package:horus_system/core/domain/value_objects/currency_configuration.dart';
import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/usecases/convert_instants_to_business_local_date_times_usecase.dart';
import 'package:horus_system/core/usecases/get_company_business_date_usecase.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/audit/domain/entities/audit_entity_type.dart';
import 'package:horus_system/features/audit/domain/entities/audit_log.dart';
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
import 'package:horus_system/features/expenses/domain/entities/expense_attribution.dart';
import 'package:horus_system/features/expenses/domain/entities/expense_funding_source.dart';
import 'package:horus_system/features/expenses/domain/entities/expense_ledger_entry.dart';
import 'package:horus_system/features/expenses/domain/failures/expense_ledger_failure_codes.dart';
import 'package:horus_system/features/expenses/domain/repositories/expense_ledger_repository.dart';
import 'package:horus_system/features/expenses/domain/usecases/can_manage_trip_attributed_expense_usecase.dart';
import 'package:horus_system/features/expenses/domain/usecases/create_trip_expense_usecase.dart';
import 'package:horus_system/features/expenses/domain/usecases/get_trip_expense_ledger_entries_usecase.dart';
import 'package:horus_system/features/expenses/domain/usecases/void_expense_ledger_entry_usecase.dart';
import 'package:horus_system/features/expenses/domain/usecases/create_expense_ledger_entry_usecase.dart';
import 'package:horus_system/features/trips/domain/entities/trip_document.dart';
import 'package:horus_system/features/trips/domain/entities/trip_document_kind.dart';
import 'package:horus_system/features/trips/domain/entities/trip_entity.dart';
import 'package:horus_system/features/trips/domain/entities/trip_status.dart';
import 'package:horus_system/features/trips/domain/entities/trip_status_history.dart';
import 'package:horus_system/features/trips/domain/failures/trip_document_failure_codes.dart';
import 'package:horus_system/features/trips/domain/repositories/trip_documents_repository.dart';
import 'package:horus_system/features/trips/domain/repositories/trips_repository.dart';
import 'package:horus_system/features/trips/domain/usecases/get_trip_permissions_usecase.dart';
import 'package:horus_system/features/trips/domain/usecases/has_required_trip_evidence_usecase.dart';
import 'package:horus_system/features/trips/domain/usecases/trips_usecases.dart';
import 'package:horus_system/features/trips/domain/value_objects/trip_number.dart';
import 'package:horus_system/features/trips/presentation/cubit/trips_cubit.dart';
import 'package:horus_system/features/trips/presentation/cubit/trips_state.dart';

import '../../../../helpers/fake_business_time_zone_converter.dart';

void main() {
  test(
    'duplicate document hints coalesce without clearing visible documents',
    () async {
      final documents = _DocumentsRepository()..current = [_oldDocument];
      final cubit = _buildCubit(documents);
      addTearDown(cubit.close);
      await cubit.loadTrips(_companyA);
      await cubit.loadTripDetails(_tripA);

      final delayed = Completer<Result<List<TripDocument>>>();
      documents.pendingReads.add(delayed);
      final first = cubit.refreshSelectedTripDocumentsFromRealtime();
      await Future<void>.delayed(Duration.zero);
      expect((cubit.state as TripsLoaded).selectedTripDocuments, [
        _oldDocument,
      ]);
      expect((cubit.state as TripsLoaded).isDocumentsLoading, isFalse);

      await cubit.refreshSelectedTripDocumentsFromRealtime();
      documents.current = [_newDocument];
      delayed.complete(Success([_oldDocument]));
      await first;

      final latest = cubit.state as TripsLoaded;
      expect(documents.reads, 3);
      expect(latest.selectedTripDocuments, [_newDocument]);
      expect(latest.isDocumentsLoading, isFalse);
      expect(latest.selectedTrip?.id, _tripA.id);
    },
  );

  test('late document response cannot cross company boundaries', () async {
    final documents = _DocumentsRepository()..current = [_oldDocument];
    final cubit = _buildCubit(documents);
    addTearDown(cubit.close);
    await cubit.loadTrips(_companyA);
    await cubit.loadTripDetails(_tripA);

    final delayed = Completer<Result<List<TripDocument>>>();
    documents.pendingReads.add(delayed);
    final refresh = cubit.refreshSelectedTripDocumentsFromRealtime();
    await Future<void>.delayed(Duration.zero);
    await cubit.loadTrips(_companyB);
    delayed.complete(Success([_oldDocument]));
    await refresh;

    final latest = cubit.state as TripsLoaded;
    expect(latest.currentCompanyContext.companyId, 'company-b');
    expect(latest.selectedTrip, isNull);
    expect(latest.selectedTripDocuments, isEmpty);
  });

  test('server permission denial clears stale document metadata', () async {
    final documents = _DocumentsRepository()..current = [_oldDocument];
    final cubit = _buildCubit(documents);
    addTearDown(cubit.close);
    await cubit.loadTrips(_companyA);
    await cubit.loadTripDetails(_tripA);

    documents.results.add(
      const FailureResult<List<TripDocument>>(
        PermissionFailure(code: TripDocumentFailureCodes.permissionView),
      ),
    );
    await cubit.refreshSelectedTripDocumentsFromRealtime();

    final latest = cubit.state as TripsLoaded;
    expect(latest.selectedTripDocuments, isEmpty);
    expect(latest.hasRequiredTripEvidence, isFalse);
    expect(
      latest.documentsFailure?.code,
      TripDocumentFailureCodes.permissionView,
    );
  });

  test('document hint waits for an active local upload', () async {
    final documents = _DocumentsRepository()..current = [_oldDocument];
    final cubit = _buildCubit(documents);
    addTearDown(cubit.close);
    await cubit.loadTrips(_companyA);
    await cubit.loadTripDetails(_tripA);

    final mutation = Completer<Result<TripDocument>>();
    documents.pendingUpload = mutation;
    final uploading = cubit.uploadTripDocument(
      tripId: _tripA.id,
      kind: TripDocumentKind.waybill,
      document: BusinessDocumentFile(
        bytes: Uint8List.fromList([1, 2, 3]),
        fileName: 'replacement.pdf',
      ),
    );
    await Future<void>.delayed(Duration.zero);
    expect((cubit.state as TripsLoaded).isTripDocumentMutating, isTrue);

    final readsBeforeHint = documents.reads;
    await cubit.refreshSelectedTripDocumentsFromRealtime();
    expect(documents.reads, readsBeforeHint);
    expect((cubit.state as TripsLoaded).selectedTripDocuments, [_oldDocument]);

    documents.current = [_oldDocument, _newDocument];
    mutation.complete(Success(_newDocument));
    await uploading;
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    final latest = cubit.state as TripsLoaded;
    expect(latest.isTripDocumentMutating, isFalse);
    expect(latest.selectedTripDocuments, contains(_newDocument));
    expect(documents.reads, greaterThan(readsBeforeHint));
  });
  test(
    'financial hints coalesce and silently refresh selected ledger',
    () async {
      final documents = _DocumentsRepository();
      final ledger = _ExpensesRepository();
      final cubit = _buildCubit(documents, expenseLedger: ledger);
      addTearDown(cubit.close);
      await cubit.loadTrips(_financeCompanyA);
      await cubit.loadTripDetails(_tripA);

      final originalReads = ledger.reads;
      final delayed = Completer<Result<List<ExpenseLedgerEntry>>>();
      ledger.pendingReads.add(delayed);

      final refresh = cubit.refreshSelectedTripFinancialsFromRealtime();
      await Future<void>.delayed(Duration.zero);
      expect((cubit.state as TripsLoaded).isExpensesLoading, isFalse);

      await cubit.refreshSelectedTripFinancialsFromRealtime();
      final updated = _expense('new-financial-entry');
      ledger.current = [updated];
      delayed.complete(const Success([]));
      await refresh;

      final latest = cubit.state as TripsLoaded;
      expect(ledger.reads, originalReads + 2);
      expect(latest.selectedTripExpenses, [updated]);
      expect(latest.selectedTrip?.id, _tripA.id);
      expect(latest.isExpensesLoading, isFalse);
    },
  );

  test('late financial hints cannot update another company session', () async {
    final documents = _DocumentsRepository();
    final ledger = _ExpensesRepository()..current = [_expense('old')];
    final cubit = _buildCubit(documents, expenseLedger: ledger);
    addTearDown(cubit.close);
    await cubit.loadTrips(_financeCompanyA);
    await cubit.loadTripDetails(_tripA);

    final delayed = Completer<Result<List<ExpenseLedgerEntry>>>();
    ledger.pendingReads.add(delayed);
    final refresh = cubit.refreshSelectedTripFinancialsFromRealtime();
    await Future<void>.delayed(Duration.zero);

    await cubit.loadTrips(_companyB);
    delayed.complete(Success([_expense('stale')]));
    await refresh;

    final latest = cubit.state as TripsLoaded;
    expect(latest.currentCompanyContext.companyId, 'company-b');
    expect(latest.selectedTripExpenses, isEmpty);
    expect(latest.selectedTrip, isNull);
  });

  test(
    'financial refresh clears stale entries on permission revocation',
    () async {
      final ledger = _ExpensesRepository()..current = [_expense('old')];
      final cubit = _buildCubit(_DocumentsRepository(), expenseLedger: ledger);
      addTearDown(cubit.close);
      await cubit.loadTrips(_financeCompanyA);
      await cubit.loadTripDetails(_tripA);
      expect((cubit.state as TripsLoaded).selectedTripExpenses, hasLength(1));

      ledger.pendingResults.add(
        const FailureResult<List<ExpenseLedgerEntry>>(
          PermissionFailure(code: ExpenseLedgerFailureCodes.permissionView),
        ),
      );
      await cubit.refreshSelectedTripFinancialsFromRealtime();

      final current = cubit.state as TripsLoaded;
      expect(current.selectedTripExpenses, isEmpty);
      expect(current.selectedTripTotalExpenses, isNull);
      expect(current.selectedTripNetProfit, isNull);
      expect(
        current.expensesFailure?.code,
        ExpenseLedgerFailureCodes.permissionView,
      );
    },
  );

  test('operations never perform financial refresh', () async {
    final ledger = _ExpensesRepository();
    final cubit = _buildCubit(_DocumentsRepository(), expenseLedger: ledger);
    addTearDown(cubit.close);
    await cubit.loadTrips(_companyA);
    await cubit.loadTripDetails(_tripA);

    final reads = ledger.reads;
    await cubit.refreshSelectedTripFinancialsFromRealtime();
    expect(ledger.reads, reads);
  });
}

const _companyA = CurrentCompanyContext(
  company: Company(
    id: 'company-a',
    name: 'Company A',
    baseCurrencyCode: 'AED',
    baseCurrencyFractionDigits: 2,
    businessTimezone: 'UTC',
  ),
  role: CompanyRole.operations,
);

const _financeCompanyA = CurrentCompanyContext(
  company: Company(
    id: 'company-a',
    name: 'Company A',
    baseCurrencyCode: 'AED',
    baseCurrencyFractionDigits: 2,
    businessTimezone: 'UTC',
  ),
  role: CompanyRole.accountant,
);

const _companyB = CurrentCompanyContext(
  company: Company(
    id: 'company-b',
    name: 'Company B',
    baseCurrencyCode: 'AED',
    baseCurrencyFractionDigits: 2,
    businessTimezone: 'UTC',
  ),
  role: CompanyRole.operations,
);

final _tripA = TripEntity(
  id: 'trip-a',
  companyId: 'company-a',
  tripNumber: TripNumber.tryParse('TRP-2026-000001')!,
  customerId: 'customer-a',
  routeId: 'route-a',
  status: TripStatus.created,
);

TripDocument _document(String id) => TripDocument(
  id: id,
  companyId: 'company-a',
  tripId: 'trip-a',
  kind: TripDocumentKind.waybill,
  originalFileName: '$id.pdf',
  mimeType: 'application/pdf',
  sizeBytes: 1024,
  uploadedAt: DateTime.utc(2026, 10, 20),
);

final _oldDocument = _document('doc-old');
final _newDocument = _document('doc-new');

TripsCubit _buildCubit(
  _DocumentsRepository documents, {
  _ExpensesRepository? expenseLedger,
}) {
  const converter = FakeBusinessTimeZoneConverter();
  final trips = _TripsRepository();
  final expenses = expenseLedger ?? _ExpensesRepository();
  final types = _ExpenseTypesRepository();

  return TripsCubit(
    getTripsUseCase: GetTripsUseCase(trips),
    getTripPermissionsUseCase: const GetTripPermissionsUseCase(),
    canManageTripAttributedExpenseUseCase:
        const CanManageTripAttributedExpenseUseCase(),
    getTripDetailsUseCase: GetTripDetailsUseCase(trips),
    getTripFormLookupsUseCase: GetTripFormLookupsUseCase(trips),
    createTripUseCase: CreateTripUseCase(trips),
    saveTripUseCase: SaveTripUseCase(trips),
    updateTripStatusUseCase: UpdateTripStatusUseCase(trips, documents),
    getTripStatusHistoryUseCase: GetTripStatusHistoryUseCase(trips),
    getTripDocumentsUseCase: GetTripDocumentsUseCase(documents),
    hasRequiredTripEvidenceUseCase: const HasRequiredTripEvidenceUseCase(),
    uploadTripDocumentUseCase: UploadTripDocumentUseCase(documents),
    getTripDocumentAccessUseCase: GetTripDocumentAccessUseCase(documents),
    downloadTripDocumentUseCase: DownloadTripDocumentUseCase(documents),
    removeTripDocumentUseCase: RemoveTripDocumentUseCase(documents),
    replaceTripDocumentUseCase: ReplaceTripDocumentUseCase(documents),
    calculateTripNetProfitUseCase: const CalculateTripNetProfitUseCase(),
    getTripBusinessLocalTimestampsUseCase:
        const GetTripBusinessLocalTimestampsUseCase(converter),
    resolveTripBusinessLocalTimestampsUseCase:
        const ResolveTripBusinessLocalTimestampsUseCase(converter),
    convertInstantsToBusinessLocalDateTimesUseCase:
        const ConvertInstantsToBusinessLocalDateTimesUseCase(converter),
    getCompanyBusinessDateUseCase: GetCompanyBusinessDateUseCase(
      _BusinessDateProvider(),
    ),
    getTripAuditLogsUseCase: GetEntityAuditLogsUseCase(_AuditRepository()),
    getTripExpenseLedgerEntriesUseCase: GetTripExpenseLedgerEntriesUseCase(
      expenses,
    ),
    getExpenseTypeCatalogUseCase: GetExpenseTypeCatalogUseCase(types),
    getLedgerEligibleExpenseTypesUseCase: GetLedgerEligibleExpenseTypesUseCase(
      types,
    ),
    createTripExpenseUseCase: CreateTripExpenseUseCase(
      CreateExpenseLedgerEntryUseCase(expenses),
    ),
    voidExpenseLedgerEntryUseCase: VoidExpenseLedgerEntryUseCase(expenses),
  );
}

final class _TripsRepository implements TripsRepository {
  @override
  Future<Result<List<TripEntity>>> getTrips({
    required String companyId,
    required CurrencyConfiguration? financialConfiguration,
  }) async => Success(companyId == 'company-a' ? [_tripA] : <TripEntity>[]);

  @override
  Future<Result<TripEntity>> getTripDetails({
    required String companyId,
    required String id,
    required CurrencyConfiguration? financialConfiguration,
  }) async => Success(_tripA);

  @override
  Future<Result<List<TripStatusHistory>>> getTripStatusHistory({
    required String companyId,
    required String tripId,
  }) async => const Success([]);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _DocumentsRepository implements TripDocumentsRepository {
  List<TripDocument> current = [];
  final Queue<Completer<Result<List<TripDocument>>>> pendingReads = Queue();
  final Queue<Result<List<TripDocument>>> results = Queue();
  Completer<Result<TripDocument>>? pendingUpload;
  int reads = 0;

  @override
  Future<Result<List<TripDocument>>> getActiveDocuments({
    required String companyId,
    required String tripId,
  }) {
    reads++;
    if (pendingReads.isNotEmpty) return pendingReads.removeFirst().future;
    if (results.isNotEmpty) return Future.value(results.removeFirst());
    return Future.value(Success(List<TripDocument>.of(current)));
  }

  @override
  Future<Result<TripDocument>> upload({
    required String companyId,
    required String tripId,
    required TripDocumentKind kind,
    required BusinessDocumentFile document,
  }) => pendingUpload?.future ?? Future.value(Success(_newDocument));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _AuditRepository implements AuditLogRepository {
  @override
  Future<Result<List<AuditLog>>> getEntityAuditLogs({
    required String companyId,
    required AuditModule module,
    required AuditEntityType entityType,
    required String entityId,
  }) async => const Success([]);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

ExpenseLedgerEntry _expense(String id) => ExpenseLedgerEntry(
  id: id,
  companyId: 'company-a',
  expenseTypeId: 'expense-type',
  amount: Money(minorUnits: 1250, currency: CurrencyCode.tryParse('AED')!),
  currencyFractionDigits: 2,
  expenseDate: BusinessDate(year: 2026, month: 10, day: 20),
  fundingSource: ExpenseFundingSource.company,
  attribution: const ExpenseAttribution(tripId: 'trip-a'),
  isVoided: false,
);

final class _ExpensesRepository implements ExpenseLedgerRepository {
  final Queue<Completer<Result<List<ExpenseLedgerEntry>>>> pendingReads =
      Queue();
  final Queue<Result<List<ExpenseLedgerEntry>>> pendingResults = Queue();
  List<ExpenseLedgerEntry> current = [];
  int reads = 0;

  @override
  Future<Result<List<ExpenseLedgerEntry>>> getEntriesForTrip({
    required String companyId,
    required String tripId,
    bool includeVoided = false,
  }) {
    reads++;
    if (pendingReads.isNotEmpty) return pendingReads.removeFirst().future;
    if (pendingResults.isNotEmpty) {
      return Future.value(pendingResults.removeFirst());
    }
    return Future.value(Success(List<ExpenseLedgerEntry>.of(current)));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _ExpenseTypesRepository implements ExpenseTypesRepository {
  @override
  Future<Result<List<ExpenseType>>> getExpenseTypes({
    required String companyId,
  }) async => const Success([]);

  @override
  Future<Result<List<ExpenseType>>> getLedgerEligibleExpenseTypes({
    required String companyId,
  }) async => const Success([]);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _BusinessDateProvider implements CompanyBusinessDateProvider {
  @override
  Future<Result<BusinessDate>> getBusinessDate({
    required String companyId,
  }) async => Success(BusinessDate(year: 2026, month: 10, day: 20));
}
