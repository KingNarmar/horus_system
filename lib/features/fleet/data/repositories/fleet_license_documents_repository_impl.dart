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
import '../../domain/entities/fleet_license_document_file_side.dart';
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
  Future<Result<FleetLicenseDocument>> createWithFile({
    required FleetLicenseDocumentTarget target,
    required FleetLicenseDocumentFileSide side,
    required BusinessDocumentFile file,
    BusinessDate? newLicenseExpiryDate,
  }) async {
    final uploadedResult = await _uploadFile(target: target, file: file);
    final uploadedFailure = uploadedResult.failureOrNull;
    if (uploadedFailure != null) return FailureResult(uploadedFailure);

    final uploaded = uploadedResult.dataOrNull;
    if (uploaded == null) return _unexpectedDocumentFailure();

    final registrationResult = await _registerWithCompensation<String>(
      target: target,
      uploaded: uploaded,
      register: () => remoteDataSource.createDocumentWithFile(
        target: target,
        side: side,
        storageReference: uploaded.reference.value,
        originalFileName: uploaded.file.fileName.trim(),
        mimeType: uploaded.mimeType,
        sizeBytes: uploaded.file.sizeInBytes,
        licenseExpiryDate: DbDate.encodeNullable(newLicenseExpiryDate),
      ),
    );
    final registrationFailure = registrationResult.failureOrNull;
    if (registrationFailure != null) {
      return FailureResult(registrationFailure);
    }

    final documentId = registrationResult.dataOrNull;
    if (documentId == null) return _unexpectedDocumentFailure();
    return _loadRegisteredDocument(target: target, documentId: documentId);
  }

  @override
  Future<Result<FleetLicenseDocument>> addFile({
    required FleetLicenseDocumentTarget target,
    required String documentId,
    required FleetLicenseDocumentFileSide side,
    required BusinessDocumentFile file,
    BusinessDate? newLicenseExpiryDate,
  }) async {
    final currentResult = await _getActiveDocumentModelById(
      target: target,
      documentId: documentId,
    );
    final currentFailure = currentResult.failureOrNull;
    if (currentFailure != null) return FailureResult(currentFailure);

    final uploadedResult = await _uploadFile(target: target, file: file);
    final uploadedFailure = uploadedResult.failureOrNull;
    if (uploadedFailure != null) return FailureResult(uploadedFailure);

    final uploaded = uploadedResult.dataOrNull;
    if (uploaded == null) return _unexpectedDocumentFailure();

    final registrationResult = await _registerWithCompensation<void>(
      target: target,
      uploaded: uploaded,
      register: () => remoteDataSource.addDocumentFile(
        target: target,
        documentId: documentId,
        side: side,
        storageReference: uploaded.reference.value,
        originalFileName: uploaded.file.fileName.trim(),
        mimeType: uploaded.mimeType,
        sizeBytes: uploaded.file.sizeInBytes,
        licenseExpiryDate: DbDate.encodeNullable(newLicenseExpiryDate),
      ),
    );
    final registrationFailure = registrationResult.failureOrNull;
    if (registrationFailure != null) {
      return FailureResult(registrationFailure);
    }

    return _loadRegisteredDocument(target: target, documentId: documentId);
  }

  @override
  Future<Result<BusinessDocumentAccess>> createTemporaryAccess({
    required FleetLicenseDocumentTarget target,
    required String documentId,
    required String fileId,
  }) async {
    final modelResult = await _getActiveDocumentModelById(
      target: target,
      documentId: documentId,
    );
    final failure = modelResult.failureOrNull;
    if (failure != null) return FailureResult(failure);

    final file = modelResult.dataOrNull?.activeFileById(fileId);
    if (file == null) {
      return const FailureResult(
        NotFoundFailure(code: FleetLicenseDocumentFailureCodes.fileNotFound),
      );
    }

    return businessDocumentRepository.createTemporaryAccess(
      companyId: target.companyId,
      reference: BusinessDocumentReference(file.storageReference),
    );
  }

  @override
  Future<Result<Uint8List>> download({
    required FleetLicenseDocumentTarget target,
    required String documentId,
    required String fileId,
  }) async {
    final modelResult = await _getActiveDocumentModelById(
      target: target,
      documentId: documentId,
    );
    final failure = modelResult.failureOrNull;
    if (failure != null) return FailureResult(failure);

    final file = modelResult.dataOrNull?.activeFileById(fileId);
    if (file == null) {
      return const FailureResult(
        NotFoundFailure(code: FleetLicenseDocumentFailureCodes.fileNotFound),
      );
    }

    return businessDocumentRepository.download(
      companyId: target.companyId,
      reference: BusinessDocumentReference(file.storageReference),
    );
  }

  @override
  Future<Result<FleetLicenseDocument>> replaceFile({
    required FleetLicenseDocumentTarget target,
    required String documentId,
    required String fileId,
    required FleetLicenseDocumentFileSide side,
    required BusinessDocumentFile replacement,
    BusinessDate? newLicenseExpiryDate,
  }) async {
    final currentResult = await _getActiveDocumentModelById(
      target: target,
      documentId: documentId,
    );
    final currentFailure = currentResult.failureOrNull;
    if (currentFailure != null) return FailureResult(currentFailure);
    if (currentResult.dataOrNull?.activeFileById(fileId) == null) {
      return const FailureResult(
        NotFoundFailure(code: FleetLicenseDocumentFailureCodes.fileNotFound),
      );
    }

    final uploadedResult = await _uploadFile(target: target, file: replacement);
    final uploadedFailure = uploadedResult.failureOrNull;
    if (uploadedFailure != null) return FailureResult(uploadedFailure);

    final uploaded = uploadedResult.dataOrNull;
    if (uploaded == null) return _unexpectedDocumentFailure();

    final registrationResult = await _registerWithCompensation<void>(
      target: target,
      uploaded: uploaded,
      register: () => remoteDataSource.replaceDocumentFile(
        target: target,
        documentId: documentId,
        fileId: fileId,
        side: side,
        storageReference: uploaded.reference.value,
        originalFileName: uploaded.file.fileName.trim(),
        mimeType: uploaded.mimeType,
        sizeBytes: uploaded.file.sizeInBytes,
        licenseExpiryDate: DbDate.encodeNullable(newLicenseExpiryDate),
      ),
    );
    final registrationFailure = registrationResult.failureOrNull;
    if (registrationFailure != null) {
      return FailureResult(registrationFailure);
    }

    return _loadRegisteredDocument(target: target, documentId: documentId);
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

  Future<Result<_UploadedFleetLicenseFile>> _uploadFile({
    required FleetLicenseDocumentTarget target,
    required BusinessDocumentFile file,
  }) async {
    final uploadResult = await businessDocumentRepository.upload(
      location: BusinessDocumentLocation(
        companyId: target.companyId,
        scope: FleetLicenseDocumentStorageSegments.scopeFor(target.assetType),
        entityId: target.assetId,
        documentKind: FleetLicenseDocumentStorageSegments.documentKind,
      ),
      file: file,
    );
    final failure = uploadResult.failureOrNull;
    if (failure != null) return FailureResult(failure);

    final reference = uploadResult.dataOrNull;
    final mimeType = filePolicy.contentTypeFor(file);
    if (reference == null || mimeType == null) {
      return const FailureResult(
        UnexpectedFailure(
          code: FleetLicenseDocumentFailureCodes.unexpectedError,
        ),
      );
    }

    return Success(
      _UploadedFleetLicenseFile(
        reference: reference,
        file: file,
        mimeType: mimeType,
      ),
    );
  }

  Future<Result<T>> _registerWithCompensation<T>({
    required FleetLicenseDocumentTarget target,
    required _UploadedFleetLicenseFile uploaded,
    required Future<T> Function() register,
  }) async {
    try {
      return Success(await register());
    } on PostgrestException catch (error) {
      final cleanupFailure = await _cleanupUploadedReference(
        companyId: target.companyId,
        reference: uploaded.reference,
      );
      if (cleanupFailure != null) return FailureResult(cleanupFailure);
      return FailureResult(failureMapper.fromPostgrest(error));
    } catch (error) {
      final cleanupFailure = await _cleanupUploadedReference(
        companyId: target.companyId,
        reference: uploaded.reference,
      );
      if (cleanupFailure != null) return FailureResult(cleanupFailure);
      return FailureResult(failureMapper.fromUnexpected(error));
    }
  }

  Future<Result<FleetLicenseDocument>> _loadRegisteredDocument({
    required FleetLicenseDocumentTarget target,
    required String documentId,
  }) async {
    final modelResult = await _getActiveDocumentModelById(
      target: target,
      documentId: documentId,
    );
    final failure = modelResult.failureOrNull;
    if (failure != null) return FailureResult(failure);

    final model = modelResult.dataOrNull;
    if (model == null) return _unexpectedDocumentFailure();
    return Success(model.toEntity());
  }

  Future<Result<FleetLicenseDocumentModel>> _getActiveDocumentModelById({
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

  FailureResult<FleetLicenseDocument> _unexpectedDocumentFailure() {
    return const FailureResult(
      UnexpectedFailure(code: FleetLicenseDocumentFailureCodes.unexpectedError),
    );
  }
}

final class _UploadedFleetLicenseFile {
  final BusinessDocumentReference reference;
  final BusinessDocumentFile file;
  final String mimeType;

  const _UploadedFleetLicenseFile({
    required this.reference,
    required this.file,
    required this.mimeType,
  });
}
