import 'dart:typed_data';

import 'package:horus_system/core/documents/data/datasources/business_document_storage_remote_data_source.dart';
import 'package:horus_system/core/documents/data/datasources/business_document_upload_reservation_remote_data_source.dart';
import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/documents/data/repositories/business_document_storage_repository_impl.dart';
import 'package:horus_system/core/documents/data/services/business_document_object_path_builder.dart';
import 'package:horus_system/core/documents/domain/entities/business_document_file.dart';
import 'package:horus_system/core/documents/domain/entities/business_document_location.dart';
import 'package:horus_system/core/documents/domain/entities/business_document_reference.dart';
import 'package:horus_system/core/documents/domain/failures/business_document_failure_codes.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;
import 'package:test/test.dart';

void main() {
  const companyId = '11111111-1111-1111-1111-111111111111';
  const entityId = '22222222-2222-2222-2222-222222222222';

  BusinessDocumentStorageRepositoryImpl createRepository(
    _FakeBusinessDocumentStorageRemoteDataSource remote, {
    _FakeReservations? reservation,
  }) {
    return BusinessDocumentStorageRepositoryImpl(
      remoteDataSource: remote,
      reservationDataSource: reservation ?? _FakeReservations(),
      pathBuilder: BusinessDocumentObjectPathBuilder(
        tokenFactory: () => 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
      ),
    );
  }

  group('BusinessDocumentStorageRepositoryImpl', () {
    test('uploads validated files using a generated safe reference', () async {
      final remote = _FakeBusinessDocumentStorageRemoteDataSource();
      final reservations = _FakeReservations();
      final repository = createRepository(remote, reservation: reservations);

      final result = await repository.upload(
        location: const BusinessDocumentLocation(
          companyId: companyId,
          scope: 'trips',
          entityId: entityId,
          documentKind: 'delivery-evidence',
        ),
        file: BusinessDocumentFile(
          bytes: Uint8List.fromList([1, 2, 3]),
          fileName: 'proof.pdf',
          mimeType: 'application/pdf',
        ),
      );

      expect(result.isSuccess, isTrue);
      expect(
        result.dataOrNull?.value,
        'companies/$companyId/trips/$entityId/delivery-evidence/'
        'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.pdf',
      );
      expect(reservations.reserveCount, 1);
      expect(remote.uploadCount, 1);
      expect(remote.lastContentType, 'application/pdf');
    });

    test('does not call Storage when file validation fails', () async {
      final remote = _FakeBusinessDocumentStorageRemoteDataSource();
      final reservations = _FakeReservations();
      final repository = createRepository(remote, reservation: reservations);

      final result = await repository.upload(
        location: const BusinessDocumentLocation(
          companyId: companyId,
          scope: 'trips',
          entityId: entityId,
          documentKind: 'evidence',
        ),
        file: BusinessDocumentFile(
          bytes: Uint8List.fromList([1]),
          fileName: 'proof.exe',
        ),
      );

      expect(
        result.failureOrNull?.code,
        BusinessDocumentFailureCodes.validationFileTypeUnsupported,
      );
      expect(remote.uploadCount, 0);
      expect(reservations.reserveCount, 0);
    });

    test('does not upload bytes when the server denies quota', () async {
      final remote = _FakeBusinessDocumentStorageRemoteDataSource();
      final reservations = _FakeReservations();
      final repository = createRepository(remote, reservation: reservations);
      reservations.error = const PostgrestException(
        message: BusinessDocumentFailureCodes.quotaReached,
        code: 'P2860',
      );
      final result = await repository.upload(
        location: const BusinessDocumentLocation(
          companyId: companyId,
          scope: 'trips',
          entityId: entityId,
          documentKind: 'waybill',
        ),
        file: BusinessDocumentFile(
          bytes: Uint8List.fromList([1]),
          fileName: 'proof.pdf',
        ),
      );
      expect(result.failureOrNull, isA<ConflictFailure>());
      expect(
        result.failureOrNull?.code,
        BusinessDocumentFailureCodes.quotaReached,
      );
      expect(remote.uploadCount, 0);
      reservations.error = null;
    });

    test('releases reservation after failed Storage upload', () async {
      final remote = _FakeBusinessDocumentStorageRemoteDataSource()
        ..uploadError = StateError('simulated upload failure');
      final reservations = _FakeReservations();
      final repository = createRepository(remote, reservation: reservations);
      final result = await repository.upload(
        location: const BusinessDocumentLocation(
          companyId: companyId,
          scope: 'trips',
          entityId: entityId,
          documentKind: 'waybill',
        ),
        file: BusinessDocumentFile(
          bytes: Uint8List.fromList([1]),
          fileName: 'proof.pdf',
        ),
      );
      expect(result.isSuccess, false);
      expect(remote.deleteCount, 1);
      expect(reservations.releaseCount, greaterThan(0));
    });

    test('rejects cross-tenant references before remote access', () async {
      final remote = _FakeBusinessDocumentStorageRemoteDataSource();
      final repository = createRepository(remote);
      const reference = BusinessDocumentReference(
        'companies/$companyId/trips/$entityId/evidence/'
        'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.pdf',
      );

      final result = await repository.download(
        companyId: '33333333-3333-3333-3333-333333333333',
        reference: reference,
      );

      expect(
        result.failureOrNull?.code,
        BusinessDocumentFailureCodes.permissionAccess,
      );
      expect(remote.downloadCount, 0);
    });

    test('supports download, temporary access, and delete lifecycle', () async {
      final remote = _FakeBusinessDocumentStorageRemoteDataSource();
      final reservations = _FakeReservations();
      final repository = createRepository(remote, reservation: reservations);
      const reference = BusinessDocumentReference(
        'companies/$companyId/trips/$entityId/evidence/'
        'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.pdf',
      );

      final download = await repository.download(
        companyId: companyId,
        reference: reference,
      );
      final access = await repository.createTemporaryAccess(
        companyId: companyId,
        reference: reference,
      );
      final deleted = await repository.delete(
        companyId: companyId,
        reference: reference,
      );

      expect(download.dataOrNull, orderedEquals([7, 8, 9]));
      expect(access.dataOrNull?.value, 'https://example.test/signed');
      expect(deleted.isSuccess, isTrue);
      expect(remote.downloadCount, 1);
      expect(remote.signedUrlCount, 1);
      expect(remote.deleteCount, 1);
      expect(reservations.releaseCount, 1);
    });
  });
}

final class _FakeBusinessDocumentStorageRemoteDataSource
    implements BusinessDocumentStorageRemoteDataSource {
  int uploadCount = 0;
  int downloadCount = 0;
  int signedUrlCount = 0;
  int deleteCount = 0;
  String? lastContentType;
  Object? uploadError;

  @override
  Future<void> upload({
    required String objectKey,
    required Uint8List bytes,
    required String contentType,
  }) async {
    uploadCount++;
    if (uploadError case final Object error) throw error;
    lastContentType = contentType;
  }

  @override
  Future<Uint8List> download({required String objectKey}) async {
    downloadCount++;
    return Uint8List.fromList([7, 8, 9]);
  }

  @override
  Future<String> createSignedUrl({required String objectKey}) async {
    signedUrlCount++;
    return 'https://example.test/signed';
  }

  @override
  Future<void> delete({required String objectKey}) async {
    deleteCount++;
  }
}

final class _FakeReservations
    implements BusinessDocumentUploadReservationRemoteDataSource {
  int reserveCount = 0;
  int releaseCount = 0;
  PostgrestException? error;

  @override
  Future<void> reserve({
    required String companyId,
    required String operationId,
    required String bucketId,
    required String storageReference,
    String? replacesReference,
  }) async {
    reserveCount++;
    if (error case final PostgrestException failure) throw failure;
  }

  @override
  Future<void> releaseByReference({
    required String companyId,
    required String storageReference,
  }) async {
    releaseCount++;
  }
}
