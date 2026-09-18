import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/core/documents/domain/entities/business_document_access.dart';
import 'package:horus_system/core/documents/domain/entities/business_document_file.dart';
import 'package:horus_system/core/documents/domain/entities/business_document_location.dart';
import 'package:horus_system/core/documents/domain/entities/business_document_reference.dart';
import 'package:horus_system/core/documents/domain/repositories/business_document_repository.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/fleet/data/datasources/fleet_license_documents_remote_data_source.dart';
import 'package:horus_system/features/fleet/data/models/fleet_license_document_file_model.dart';
import 'package:horus_system/features/fleet/data/models/fleet_license_document_model.dart';
import 'package:horus_system/features/fleet/data/repositories/fleet_license_documents_repository_impl.dart';
import 'package:horus_system/features/fleet/domain/entities/fleet_asset_type.dart';
import 'package:horus_system/features/fleet/domain/entities/fleet_license_document_file_side.dart';
import 'package:horus_system/features/fleet/domain/entities/fleet_license_document_target.dart';
import 'package:horus_system/features/fleet/domain/failures/fleet_license_document_failure_codes.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('FleetLicenseDocumentsRepositoryImpl', () {
    test('creates first front file in Fleet-owned storage scope', () async {
      final remote = _FakeRemoteDataSource();
      final storage = _FakeBusinessDocumentRepository();
      final repository = FleetLicenseDocumentsRepositoryImpl(
        remoteDataSource: remote,
        businessDocumentRepository: storage,
      );

      final result = await repository.createWithFile(
        target: _tractorTarget,
        side: FleetLicenseDocumentFileSide.front,
        file: _file,
      );

      expect(result, isA<Success>());
      expect(storage.lastUploadLocation?.scope, 'tractor-heads');
      expect(storage.lastUploadLocation?.entityId, _assetId);
      expect(storage.lastUploadLocation?.documentKind, 'license');
      expect(remote.lastSide, FleetLicenseDocumentFileSide.front);
    });

    test('adds back file to the existing document', () async {
      final remote = _FakeRemoteDataSource();
      final storage = _FakeBusinessDocumentRepository();
      final repository = FleetLicenseDocumentsRepositoryImpl(
        remoteDataSource: remote,
        businessDocumentRepository: storage,
      );

      final result = await repository.addFile(
        target: _tractorTarget,
        documentId: 'document-1',
        side: FleetLicenseDocumentFileSide.back,
        file: _file,
      );

      expect(result, isA<Success>());
      expect(remote.addCalls, 1);
      expect(remote.lastSide, FleetLicenseDocumentFileSide.back);
      expect(remote.lastDocumentId, 'document-1');
    });

    test('cleans up only new upload when DB registration fails', () async {
      final remote = _FakeRemoteDataSource()
        ..createError = const PostgrestException(
          message: 'side conflict',
          code: 'P3436',
        );
      final storage = _FakeBusinessDocumentRepository();
      final repository = FleetLicenseDocumentsRepositoryImpl(
        remoteDataSource: remote,
        businessDocumentRepository: storage,
      );

      final result = await repository.createWithFile(
        target: _tractorTarget,
        side: FleetLicenseDocumentFileSide.front,
        file: _file,
      );

      expect(storage.deleteCalls, 1);
      expect(
        result.failureOrNull?.code,
        FleetLicenseDocumentFailureCodes.conflictFileSide,
      );
    });

    test('logical remove never deletes registered Storage objects', () async {
      final remote = _FakeRemoteDataSource();
      final storage = _FakeBusinessDocumentRepository();
      final repository = FleetLicenseDocumentsRepositoryImpl(
        remoteDataSource: remote,
        businessDocumentRepository: storage,
      );

      final result = await repository.remove(
        target: _tractorTarget,
        documentId: 'document-1',
      );

      expect(result, isA<Success<void>>());
      expect(remote.removeCalls, 1);
      expect(storage.deleteCalls, 0);
    });
  });
}

const _companyId = '11111111-1111-1111-1111-111111111111';
const _assetId = '22222222-2222-2222-2222-222222222222';
const _tractorTarget = FleetLicenseDocumentTarget(
  companyId: _companyId,
  assetType: FleetAssetType.tractorHead,
  assetId: _assetId,
);
const _reference = BusinessDocumentReference(
  'companies/11111111-1111-1111-1111-111111111111/'
  'tractor-heads/22222222-2222-2222-2222-222222222222/'
  'license/0123456789abcdef0123456789abcdef.pdf',
);

final _file = BusinessDocumentFile(
  bytes: Uint8List.fromList([1, 2, 3]),
  fileName: 'license.pdf',
  mimeType: 'application/pdf',
);

final class _FakeBusinessDocumentRepository
    implements BusinessDocumentRepository {
  BusinessDocumentLocation? lastUploadLocation;
  int deleteCalls = 0;

  @override
  Future<Result<BusinessDocumentReference>> upload({
    required BusinessDocumentLocation location,
    required BusinessDocumentFile file,
  }) async {
    lastUploadLocation = location;
    return const Success(_reference);
  }

  @override
  Future<Result<void>> delete({
    required String companyId,
    required BusinessDocumentReference reference,
  }) async {
    deleteCalls++;
    return const Success<void>(null);
  }

  @override
  Future<Result<Uint8List>> download({
    required String companyId,
    required BusinessDocumentReference reference,
  }) async {
    return Success(Uint8List.fromList([1]));
  }

  @override
  Future<Result<BusinessDocumentAccess>> createTemporaryAccess({
    required String companyId,
    required BusinessDocumentReference reference,
  }) async {
    return const Success(
      BusinessDocumentAccess('https://example.test/license'),
    );
  }
}

final class _FakeRemoteDataSource
    implements FleetLicenseDocumentsRemoteDataSource {
  PostgrestException? createError;
  int addCalls = 0;
  int removeCalls = 0;
  String? lastDocumentId;
  FleetLicenseDocumentFileSide? lastSide;

  @override
  Future<FleetLicenseDocumentModel?> getActiveDocument({
    required FleetLicenseDocumentTarget target,
  }) async {
    return _model();
  }

  @override
  Future<FleetLicenseDocumentModel> getActiveDocumentById({
    required FleetLicenseDocumentTarget target,
    required String documentId,
  }) async {
    return _model();
  }

  @override
  Future<FleetLicenseDocumentModel> createDocumentWithFile({
    required FleetLicenseDocumentTarget target,
    required FleetLicenseDocumentFileSide side,
    required String storageReference,
    required String originalFileName,
    required String mimeType,
    required int sizeBytes,
    String? licenseExpiryDate,
  }) async {
    final error = createError;
    if (error != null) throw error;
    lastSide = side;
    return _model(storageReference: storageReference, side: side);
  }

  @override
  Future<FleetLicenseDocumentModel> addDocumentFile({
    required FleetLicenseDocumentTarget target,
    required String documentId,
    required FleetLicenseDocumentFileSide side,
    required String storageReference,
    required String originalFileName,
    required String mimeType,
    required int sizeBytes,
    String? licenseExpiryDate,
  }) async {
    addCalls++;
    lastDocumentId = documentId;
    lastSide = side;
    return _model(storageReference: storageReference, side: side);
  }

  @override
  Future<FleetLicenseDocumentModel> replaceDocumentFile({
    required FleetLicenseDocumentTarget target,
    required String documentId,
    required String fileId,
    required FleetLicenseDocumentFileSide side,
    required String storageReference,
    required String originalFileName,
    required String mimeType,
    required int sizeBytes,
    String? licenseExpiryDate,
  }) async {
    lastDocumentId = documentId;
    lastSide = side;
    return _model(storageReference: storageReference, side: side);
  }

  @override
  Future<void> removeDocument({
    required FleetLicenseDocumentTarget target,
    required String documentId,
  }) async {
    removeCalls++;
  }

  FleetLicenseDocumentModel _model({
    String storageReference =
        'companies/11111111-1111-1111-1111-111111111111/'
        'tractor-heads/22222222-2222-2222-2222-222222222222/'
        'license/0123456789abcdef0123456789abcdef.pdf',
    FleetLicenseDocumentFileSide side = FleetLicenseDocumentFileSide.front,
  }) {
    return FleetLicenseDocumentModel(
      id: 'document-1',
      companyId: _companyId,
      tractorHeadId: _assetId,
      files: [
        FleetLicenseDocumentFileModel(
          id: 'file-1',
          companyId: _companyId,
          licenseDocumentId: 'document-1',
          side: side,
          storageReference: storageReference,
          originalFileName: 'license.pdf',
          mimeType: 'application/pdf',
          sizeBytes: 3,
          uploadedAt: DateTime.utc(2026, 9, 18),
        ),
      ],
      uploadedAt: DateTime.utc(2026, 9, 18),
    );
  }
}
