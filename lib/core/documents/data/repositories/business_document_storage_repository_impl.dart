import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart'
    show PostgrestException, StorageException;

import '../../../data/utils/uuid_v4.dart';
import '../../../errors/common_failures.dart';
import '../../../utils/result.dart';
import '../../domain/entities/business_document_access.dart';
import '../../domain/entities/business_document_file.dart';
import '../../domain/entities/business_document_location.dart';
import '../../domain/entities/business_document_reference.dart';
import '../../domain/failures/business_document_failure_codes.dart';
import '../../domain/policies/business_document_file_policy.dart';
import '../../domain/repositories/business_document_repository.dart';
import '../constants/business_document_storage_constants.dart';
import '../datasources/business_document_storage_remote_data_source.dart';
import '../datasources/business_document_upload_reservation_remote_data_source.dart';
import '../services/business_document_object_path_builder.dart';
import 'business_document_storage_failure_mapper.dart';

final class BusinessDocumentStorageRepositoryImpl
    implements BusinessDocumentRepository {
  final BusinessDocumentStorageRemoteDataSource remoteDataSource;
  final BusinessDocumentUploadReservationRemoteDataSource reservationDataSource;
  final BusinessDocumentObjectPathBuilder pathBuilder;
  final BusinessDocumentFilePolicy filePolicy;
  final BusinessDocumentStorageFailureMapper failureMapper;

  const BusinessDocumentStorageRepositoryImpl({
    required this.remoteDataSource,
    required this.reservationDataSource,
    required this.pathBuilder,
    this.filePolicy = const BusinessDocumentFilePolicy(),
    this.failureMapper = const BusinessDocumentStorageFailureMapper(),
  });

  @override
  Future<Result<BusinessDocumentReference>> upload({
    required BusinessDocumentLocation location,
    required BusinessDocumentFile file,
  }) async {
    final validationFailure = filePolicy.validate(file);
    if (validationFailure != null) {
      return FailureResult<BusinessDocumentReference>(validationFailure);
    }

    final pathResult = pathBuilder.build(
      location: location,
      fileName: file.fileName,
    );
    if (pathResult is FailureResult<String>) {
      return FailureResult<BusinessDocumentReference>(pathResult.failure);
    }

    final objectKey = (pathResult as Success<String>).data;
    final contentType = filePolicy.contentTypeFor(file);
    if (contentType == null) {
      return const FailureResult<BusinessDocumentReference>(
        UnexpectedFailure(code: BusinessDocumentFailureCodes.unexpectedError),
      );
    }

    // The server owns capacity, concurrent reservations and the lease. Do not
    // upload any bytes until the reservation has succeeded.
    try {
      await reservationDataSource.reserve(
        companyId: location.companyId,
        operationId: newUuidV4(),
        bucketId: BusinessDocumentStorageConstants.bucket,
        storageReference: objectKey,
        replacesReference: location.replacesReference?.value,
      );
    } on PostgrestException catch (error) {
      return FailureResult<BusinessDocumentReference>(
        failureMapper.fromReservation(error),
      );
    } catch (error) {
      return FailureResult<BusinessDocumentReference>(
        failureMapper.fromUnexpected(error),
      );
    }

    try {
      await remoteDataSource.upload(
        objectKey: objectKey,
        bytes: file.bytes,
        contentType: contentType,
      );
      return Success<BusinessDocumentReference>(
        BusinessDocumentReference(objectKey),
      );
    } on StorageException catch (error) {
      final cleanupPending = await _compensateFailedUpload(
        companyId: location.companyId,
        objectKey: objectKey,
      );
      return FailureResult<BusinessDocumentReference>(
        cleanupPending ?? failureMapper.fromStorage(error),
      );
    } catch (error) {
      final cleanupPending = await _compensateFailedUpload(
        companyId: location.companyId,
        objectKey: objectKey,
      );
      return FailureResult<BusinessDocumentReference>(
        cleanupPending ?? failureMapper.fromUnexpected(error),
      );
    }
  }

  @override
  Future<Result<Uint8List>> download({
    required String companyId,
    required BusinessDocumentReference reference,
  }) async {
    final validationFailure = pathBuilder.validateReference(
      companyId: companyId,
      reference: reference,
    );
    if (validationFailure != null) {
      return FailureResult<Uint8List>(validationFailure);
    }

    try {
      final bytes = await remoteDataSource.download(objectKey: reference.value);
      return Success<Uint8List>(bytes);
    } on StorageException catch (error) {
      return FailureResult<Uint8List>(failureMapper.fromStorage(error));
    } catch (error) {
      return FailureResult<Uint8List>(failureMapper.fromUnexpected(error));
    }
  }

  @override
  Future<Result<BusinessDocumentAccess>> createTemporaryAccess({
    required String companyId,
    required BusinessDocumentReference reference,
  }) async {
    final validationFailure = pathBuilder.validateReference(
      companyId: companyId,
      reference: reference,
    );
    if (validationFailure != null) {
      return FailureResult<BusinessDocumentAccess>(validationFailure);
    }

    try {
      final value = await remoteDataSource.createSignedUrl(
        objectKey: reference.value,
      );
      return Success<BusinessDocumentAccess>(BusinessDocumentAccess(value));
    } on StorageException catch (error) {
      return FailureResult<BusinessDocumentAccess>(
        failureMapper.fromStorage(error),
      );
    } catch (error) {
      return FailureResult<BusinessDocumentAccess>(
        failureMapper.fromUnexpected(error),
      );
    }
  }

  @override
  Future<Result<void>> delete({
    required String companyId,
    required BusinessDocumentReference reference,
  }) async {
    final validationFailure = pathBuilder.validateReference(
      companyId: companyId,
      reference: reference,
    );
    if (validationFailure != null) {
      return FailureResult<void>(validationFailure);
    }

    try {
      await remoteDataSource.delete(objectKey: reference.value);
      await reservationDataSource.releaseByReference(
        companyId: companyId,
        storageReference: reference.value,
      );
      return const Success<void>(null);
    } on StorageException catch (error) {
      return FailureResult<void>(failureMapper.fromStorage(error));
    } on PostgrestException catch (error) {
      return FailureResult<void>(failureMapper.fromReservation(error));
    } catch (error) {
      return FailureResult<void>(failureMapper.fromUnexpected(error));
    }
  }

  /// Upload may fail after Storage accepts bytes. Always attempt both
  /// compensations; an incomplete cleanup is durable in the reservation
  /// ledger and is returned as a typed failure for server-side recovery.
  Future<ServerFailure?> _compensateFailedUpload({
    required String companyId,
    required String objectKey,
  }) async {
    var cleanupFailed = false;
    try {
      await remoteDataSource.delete(objectKey: objectKey);
    } catch (_) {
      cleanupFailed = true;
    }
    try {
      await reservationDataSource.releaseByReference(
        companyId: companyId,
        storageReference: objectKey,
      );
    } catch (_) {
      cleanupFailed = true;
    }
    return cleanupFailed
        ? const ServerFailure(code: BusinessDocumentFailureCodes.cleanupPending)
        : null;
  }
}
