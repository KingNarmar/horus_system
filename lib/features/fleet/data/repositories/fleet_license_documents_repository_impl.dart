import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/data/utils/db_date.dart';
import '../../../../core/documents/domain/entities/business_document_access.dart';
import '../../../../core/documents/domain/entities/business_document_file.dart';
import '../../../../core/documents/domain/entities/business_document_location.dart';
import '../../../../core/documents/domain/entities/business_document_reference.dart';
import '../../../../core/documents/domain/policies/business_document_file_policy.dart';
import '../../../../core/documents/domain/repositories/business_document_repository.dart';
import '../../../../core/domain/value_objects/business_date.dart';
import '../../../../core/errors/common_failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/fleet_license_document.dart';
import '../../domain/entities/fleet_license_document_target.dart';
import '../../domain/failures/fleet_license_document_failure_codes.dart';
import '../../domain/repositories/fleet_license_documents_repository.dart';
import '../constants/fleet_license_document_storage_segments.dart';
import '../datasources/fleet_license_documents_remote_data_source.dart';
import '../models/fleet_license_document_model.dart';
import 'fleet_license_document_repository_failure_mapper.dart';

final class FleetLicenseDocumentsRepositoryImpl
    implements FleetLicenseDocumentsRepository {
  final FleetLicenseDocumentsRemoteDataSource remoteDataSource;
  final BusinessDocumentRepository businessDocumentRepository;
  final BusinessDocumentFilePolicy filePolicy;
  final FleetLicenseDocumentRepositoryFailureMapper failureMapper;

  const FleetLicenseDocumentsRepositoryImpl({
    required this.remoteDataSource,
    required this.businessDocumentRepository,
    this.filePolicy = const BusinessDocumentFilePolicy(),
    this.failureMapper = const FleetLicenseDocumentRepositoryFailureMapper(),
  });

  @override
  Future<Result<FleetLicenseDocument?>> getActiveDocument({
    required FleetLicenseDocumentTarget target,
  }) {
    return _guard(() async {
      final model = await remoteDataSource.getActiveDocument(target: target);
      return Success(model?.toEntity());
    });
  }

  @override
  Future<Result<FleetLicenseDocument>> upload({
    required FleetLicenseDocumentTarget target,
    required BusinessDocumentFile document,
    BusinessDate? newLicenseExpiryDate,
  }) async {
    final uploadResult = await businessDocumentRepository.upload(
      location: BusinessDocumentLocation(
        companyId: target.companyId,
        scope: FleetLicenseDocumentStorageSegments.scopeFor(target.assetType),
        entityId: target.assetId,
        documentKind: FleetLicenseDocumentStorageSegments.documentKind,
      ),
      file: document,
    );
    final uploadFailure = uploadResult.failureOrNull;
    if (uploadFailure != null) return FailureResult(uploadFailure);

    final reference = uploadResult.dataOrNull;
    final mimeType = filePolicy.contentTypeFor(document);
    if (reference == null || mimeType == null) {
      return const FailureResult(
        UnexpectedFailure(
          code: FleetLicenseDocumentFailureCodes.unexpectedError,
        ),
      );
    }

    try {
      final model = await remoteDataSource.createDocument(
        target: target,
        storageReference: reference.value,
        originalFileName: document.fileName.trim(),
        mimeType: mimeType,
        sizeBytes: document.sizeInBytes,
        licenseExpiryDate: DbDate.encodeNullable(newLicenseExpiryDate),
      );
      return Success(model.toEntity());
    } on PostgrestException catch (error) {
      final cleanupFailure = await _cleanupUploadedReference(
        companyId: target.companyId,
        reference: reference,
      );
      if (cleanupFailure != null) return FailureResult(cleanupFailure);
      return FailureResult(failureMapper.fromPostgrest(error));
    } catch (error) {
      final cleanupFailure = await _cleanupUploadedReference(
        companyId: target.companyId,
        reference: reference,
      );
      if (cleanupFailure != null) return FailureResult(cleanupFailure);
      return FailureResult(failureMapper.fromUnexpected(error));
    }
  }

  @override
  Future<Result<BusinessDocumentAccess>> createTemporaryAccess({
    required FleetLicenseDocumentTarget target,
    required String documentId,
  }) async {
    final modelResult = await _getActiveDocumentById(
      target: target,
      documentId: documentId,
    );
    final failure = modelResult.failureOrNull;
    if (failure != null) return FailureResult(failure);
    final model = modelResult.dataOrNull;
    if (model == null) {
      return const FailureResult(
        UnexpectedFailure(
          code: FleetLicenseDocumentFailureCodes.unexpectedError,
        ),
      );
    }
    return businessDocumentRepository.createTemporaryAccess(
      companyId: target.companyId,
      reference: BusinessDocumentReference(model.storageReference),
    );
  }

  @override
  Future<Result<Uint8List>> download({
    required FleetLicenseDocumentTarget target,
    required String documentId,
  }) async {
    final modelResult = await _getActiveDocumentById(
      target: target,
      documentId: documentId,
    );
    final failure = modelResult.failureOrNull;
    if (failure != null) return FailureResult(failure);
    final model = modelResult.dataOrNull;
    if (model == null) {
      return const FailureResult(
        UnexpectedFailure(
          code: FleetLicenseDocumentFailureCodes.unexpectedError,
        ),
      );
    }
    return businessDocumentRepository.download(
      companyId: target.companyId,
      reference: BusinessDocumentReference(model.storageReference),
    );
  }

  @override
  Future<Result<FleetLicenseDocument>> replace({
    required FleetLicenseDocumentTarget target,
    required String documentId,
    required BusinessDocumentFile document,
    BusinessDate? newLicenseExpiryDate,
  }) async {
    final currentResult = await _getActiveDocumentById(
      target: target,
      documentId: documentId,
    );
    final currentFailure = currentResult.failureOrNull;
    if (currentFailure != null) return FailureResult(currentFailure);

    final uploadResult = await businessDocumentRepository.upload(
      location: BusinessDocumentLocation(
        companyId: target.companyId,
        scope: FleetLicenseDocumentStorageSegments.scopeFor(target.assetType),
        entityId: target.assetId,
        documentKind: FleetLicenseDocumentStorageSegments.documentKind,
      ),
      file: document,
    );
    final uploadFailure = uploadResult.failureOrNull;
    if (uploadFailure != null) return FailureResult(uploadFailure);

    final reference = uploadResult.dataOrNull;
    final mimeType = filePolicy.contentTypeFor(document);
    if (reference == null || mimeType == null) {
      return const FailureResult(
        UnexpectedFailure(
          code: FleetLicenseDocumentFailureCodes.unexpectedError,
        ),
      );
    }

    try {
      final model = await remoteDataSource.replaceDocument(
        target: target,
        documentId: documentId,
        storageReference: reference.value,
        originalFileName: document.fileName.trim(),
        mimeType: mimeType,
        sizeBytes: document.sizeInBytes,
        licenseExpiryDate: DbDate.encodeNullable(newLicenseExpiryDate),
      );
      return Success(model.toEntity());
    } on PostgrestException catch (error) {
      final cleanupFailure = await _cleanupUploadedReference(
        companyId: target.companyId,
        reference: reference,
      );
      if (cleanupFailure != null) return FailureResult(cleanupFailure);
      return FailureResult(failureMapper.fromPostgrest(error));
    } catch (error) {
      final cleanupFailure = await _cleanupUploadedReference(
        companyId: target.companyId,
        reference: reference,
      );
      if (cleanupFailure != null) return FailureResult(cleanupFailure);
      return FailureResult(failureMapper.fromUnexpected(error));
    }
  }

  @override
  Future<Result<void>> remove({
    required FleetLicenseDocumentTarget target,
    required String documentId,
  }) {
    return _guard(() async {
      await remoteDataSource.removeDocument(
        target: target,
        documentId: documentId,
      );
      return const Success<void>(null);
    });
  }

  Future<Result<FleetLicenseDocumentModel>> _getActiveDocumentById({
    required FleetLicenseDocumentTarget target,
    required String documentId,
  }) {
    return _guard(() async {
      final model = await remoteDataSource.getActiveDocumentById(
        target: target,
        documentId: documentId,
      );
      return Success(model);
    });
  }

  Future<Result<T>> _guard<T>(Future<Result<T>> Function() action) async {
    try {
      return await action();
    } on PostgrestException catch (error) {
      return FailureResult(failureMapper.fromPostgrest(error));
    } catch (error) {
      return FailureResult(failureMapper.fromUnexpected(error));
    }
  }

  Future<UnexpectedFailure?> _cleanupUploadedReference({
    required String companyId,
    required BusinessDocumentReference reference,
  }) async {
    final cleanupResult = await businessDocumentRepository.delete(
      companyId: companyId,
      reference: reference,
    );
    if (cleanupResult.failureOrNull == null) return null;
    return const UnexpectedFailure(
      code: FleetLicenseDocumentFailureCodes.compensationCleanupFailed,
    );
  }
}
