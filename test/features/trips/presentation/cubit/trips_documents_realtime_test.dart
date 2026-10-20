import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/core/documents/domain/entities/business_document_file.dart';
import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/trips/domain/entities/trip_document.dart';
import 'package:horus_system/features/trips/domain/entities/trip_document_kind.dart';
import 'package:horus_system/features/trips/domain/failures/trip_document_failure_codes.dart';
import 'package:horus_system/features/trips/presentation/cubit/trips_state.dart';

import 'trips_realtime_test_fixtures.dart';

void main() {
  test(
    'duplicate document hints coalesce without clearing visible documents',
    () async {
      final documents = FakeDocumentsRepository()..current = [oldDocument];
      final cubit = buildTripsRealtimeCubit(documents);
      addTearDown(cubit.close);
      await cubit.loadTrips(companyA);
      await cubit.loadTripDetails(tripA);

      final delayed = Completer<Result<List<TripDocument>>>();
      documents.pendingReads.add(delayed);
      final first = cubit.refreshSelectedTripDocumentsFromRealtime();
      await Future<void>.delayed(Duration.zero);
      expect((cubit.state as TripsLoaded).selectedTripDocuments, [oldDocument]);
      expect((cubit.state as TripsLoaded).isDocumentsLoading, isFalse);

      await cubit.refreshSelectedTripDocumentsFromRealtime();
      documents.current = [newDocument];
      delayed.complete(Success([oldDocument]));
      await first;

      final latest = cubit.state as TripsLoaded;
      expect(documents.reads, 3);
      expect(latest.selectedTripDocuments, [newDocument]);
      expect(latest.isDocumentsLoading, isFalse);
      expect(latest.selectedTrip?.id, tripA.id);
    },
  );

  test('late document response cannot cross company boundaries', () async {
    final documents = FakeDocumentsRepository()..current = [oldDocument];
    final cubit = buildTripsRealtimeCubit(documents);
    addTearDown(cubit.close);
    await cubit.loadTrips(companyA);
    await cubit.loadTripDetails(tripA);

    final delayed = Completer<Result<List<TripDocument>>>();
    documents.pendingReads.add(delayed);
    final refresh = cubit.refreshSelectedTripDocumentsFromRealtime();
    await Future<void>.delayed(Duration.zero);
    await cubit.loadTrips(companyB);
    delayed.complete(Success([oldDocument]));
    await refresh;

    final latest = cubit.state as TripsLoaded;
    expect(latest.currentCompanyContext.companyId, 'company-b');
    expect(latest.selectedTrip, isNull);
    expect(latest.selectedTripDocuments, isEmpty);
  });

  test('server permission denial clears stale document metadata', () async {
    final documents = FakeDocumentsRepository()..current = [oldDocument];
    final cubit = buildTripsRealtimeCubit(documents);
    addTearDown(cubit.close);
    await cubit.loadTrips(companyA);
    await cubit.loadTripDetails(tripA);

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
    final documents = FakeDocumentsRepository()..current = [oldDocument];
    final cubit = buildTripsRealtimeCubit(documents);
    addTearDown(cubit.close);
    await cubit.loadTrips(companyA);
    await cubit.loadTripDetails(tripA);

    final mutation = Completer<Result<TripDocument>>();
    documents.pendingUpload = mutation;
    final uploading = cubit.uploadTripDocument(
      tripId: tripA.id,
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
    expect((cubit.state as TripsLoaded).selectedTripDocuments, [oldDocument]);

    documents.current = [oldDocument, newDocument];
    mutation.complete(Success(newDocument));
    await uploading;
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    final latest = cubit.state as TripsLoaded;
    expect(latest.isTripDocumentMutating, isFalse);
    expect(latest.selectedTripDocuments, contains(newDocument));
    expect(documents.reads, greaterThan(readsBeforeHint));
  });
}
