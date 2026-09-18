import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/core/documents/domain/entities/business_document_access.dart';
import 'package:horus_system/core/documents/domain/entities/business_document_file.dart';
import 'package:horus_system/core/documents/domain/entities/business_document_location.dart';
import 'package:horus_system/core/documents/domain/entities/business_document_reference.dart';
import 'package:horus_system/core/documents/domain/repositories/business_document_repository.dart';
import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/trips/data/datasources/trip_documents_remote_data_source.dart';
import 'package:horus_system/features/trips/data/models/trip_document_model.dart';
import 'package:horus_system/features/trips/data/repositories/trip_documents_repository_impl.dart';
import 'package:horus_system/features/trips/domain/entities/trip_document_kind.dart';
import 'package:horus_system/features/trips/domain/failures/trip_document_failure_codes.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('TripDocumentsRepositoryImpl', () {
    test('keeps DB kind separate from the PC-03 storage path segment', () async {
      final remote = _FakeTripDocumentsRemoteDataSource();
      final storage = _FakeBusinessDocumentRepository();
      final repository = TripDocumentsRepositoryImpl(
        remoteDataSource: remote,
        businessDocumentRepository: storage,
      );

      final result = await repository.upload(
        companyId: _companyId,
        tripId: _tripId,
        kind: TripDocumentKind.loadingOrder,
        document: _file,
      );

      expect(result, isA<Success>());
      expect(storage.lastUploadLocation?.documentKind, 'loading-order');
      expect(remote.lastCreateDocumentKind, 'loading_order');
    });

    test('deletes the uploaded object when metadata creation fails', () async {
      final remote = _FakeTripDocumentsRemoteDataSource()
        ..createError = const PostgrestException(
          message: 'trip_document_max_active',
          code: 'P3423',
        );
      final storage = _FakeBusinessDocumentRepository();
      final repository = TripDocumentsRepositoryImpl(
        remoteDataSource: remote,
        businessDocumentRepository: storage,
      );

      final result = await repository.upload(
        companyId: _companyId,
        tripId: _tripId,
        kind: TripDocumentKind.waybill,
        document: _file,
      );

      expect(storage.deleteCalls, 1);
      expect(
        result.failureOrNull?.code,
        TripDocumentFailureCodes.conflictMaxActiveDocuments,
      );
    });

    test('surfaces cleanup failure instead of hiding an orphaned upload', () async {
      final remote = _FakeTripDocumentsRemoteDataSource()
        ..createError = const PostgrestException(
          message: 'metadata failed',
          code: 'XX000',
        );
      final storage = _FakeBusinessDocumentRepository()
        ..deleteResult = const FailureResult(
          ServerFailure(code: 'storage_delete_failed'),
        );
      final repository = TripDocumentsRepositoryImpl(
        remoteDataSource: remote,
        businessDocumentRepository: storage,
      );

      final result = await repository.upload(
        companyId: _companyId,
        tripId: _tripId,
        kind: TripDocumentKind.proofOfDelivery,
        document: _file,
      );

      expect(storage.deleteCalls, 1);
      expect(
        result.failureOrNull?.code,
        TripDocumentFailureCodes.compensationCleanupFailed,
      );
    });
  });
}

const _companyId = '11111111-1111-1111-1111-111111111111';
const _tripId = '22222222-2222-2222-2222-222222222222';
const _reference = BusinessDocumentReference(
  'companies/11111111-1111-1111-1111-111111111111/'
  'trips/22222222-2222-2222-2222-222222222222/'
  'waybill/0123456789abcdef0123456789abcdef.pdf',
);
final _file = BusinessDocumentFile(
  bytes: Uint8List.fromList([1, 2, 3]),
  fileName: 'evidence.pdf',
  mimeType: 'application/pdf',
);

final class _FakeBusinessDocumentRepository
    implements BusinessDocumentRepository {
  Result<void> deleteResult = const Success<void>(null);
  BusinessDocumentLocation? lastUploadLocation;
  int deleteCalls = 0;

  @override
  Future<Result<BusinessDocumentReference>> upload({
    required BusinessDocumentLocation location,
    required BusinessDocumentFile file,
  }) {
    lastUploadLocation = location;
    return Future.value(const Success(_reference));
  }

  @override
  Future<Result<void>> delete({
    required String companyId,
    required BusinessDocumentReference reference,
  }) {
    deleteCalls++;
    return Future.value(deleteResult);
  }

  @override
  Future<Result<Uint8List>> download({
    required String companyId,
    required BusinessDocumentReference reference,
  }) {
    return Future.value(Success(Uint8List.fromList([1])));
  }

  @override
  Future<Result<BusinessDocumentAccess>> createTemporaryAccess({
    required String companyId,
    required BusinessDocumentReference reference,
  }) {
    return Future.value(
      const Success(BusinessDocumentAccess('https://example.test')),
    );
  }
}

final class _FakeTripDocumentsRemoteDataSource
    implements TripDocumentsRemoteDataSource {
  PostgrestException? createError;
  String? lastCreateDocumentKind;

  @override
  Future<TripDocumentModel> createDocument({
    required String companyId,
    required String tripId,
    required String documentKind,
    required String storageReference,
    required String originalFileName,
    required String mimeType,
    required int sizeBytes,
  }) async {
    lastCreateDocumentKind = documentKind;
    final error = createError;
    if (error != null) throw error;

    return _model(kind: documentKind, storageReference: storageReference);
  }

  @override
  Future<List<TripDocumentModel>> getActiveDocuments({
    required String companyId,
    required String tripId,
  }) {
    return Future.value(const []);
  }

  @override
  Future<TripDocumentModel> getActiveDocumentById({
    required String companyId,
    required String tripId,
    required String documentId,
  }) {
    return Future.value(_model());
  }

  @override
  Future<TripDocumentModel> replaceDocument({
    required String companyId,
    required String tripId,
    required String documentId,
    required String storageReference,
    required String originalFileName,
    required String mimeType,
    required int sizeBytes,
  }) {
    return Future.value(_model(storageReference: storageReference));
  }

  @override
  Future<void> removeDocument({
    required String companyId,
    required String tripId,
    required String documentId,
  }) {
    return Future.value();
  }

  TripDocumentModel _model({
    String kind = 'waybill',
    String storageReference =
        'companies/11111111-1111-1111-1111-111111111111/'
        'trips/22222222-2222-2222-2222-222222222222/'
        'waybill/0123456789abcdef0123456789abcdef.pdf',
  }) {
    return TripDocumentModel(
      id: '33333333-3333-3333-3333-333333333333',
      companyId: _companyId,
      tripId: _tripId,
      kind: TripDocumentKindX.fromValue(kind),
      storageReference: storageReference,
      originalFileName: 'evidence.pdf',
      mimeType: 'application/pdf',
      sizeBytes: 3,
      uploadedAt: DateTime.utc(2026, 9, 18),
    );
  }
}
