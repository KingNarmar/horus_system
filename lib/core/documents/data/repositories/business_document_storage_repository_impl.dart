import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart' show StorageException;

import '../../../errors/common_failures.dart';
import '../../../utils/result.dart';
import '../../domain/entities/business_document_access.dart';
import '../../domain/entities/business_document_file.dart';
import '../../domain/entities/business_document_location.dart';
import '../../domain/entities/business_document_reference.dart';
import '../../domain/failures/business_document_failure_codes.dart';
import '../../domain/policies/business_document_file_policy.dart';
import '../../domain/repositories/business_document_repository.dart';
import '../datasources/business_document_storage_remote_data_source.dart';
import '../services/business_document_object_path_builder.dart';
import 'business_document_storage_failure_mapper.dart';

final class BusinessDocumentStorageRepositoryImpl
    implements BusinessDocumentRepository {
  final BusinessDocumentStorageRemoteDataSource remoteDataSource;
  final BusinessDocumentObjectPathBuilder pathBuilder;
  final BusinessDocumentFilePolicy filePolicy;
  final BusinessDocumentStorageFailureMapper failureMapper;

  const BusinessDocumentStorageRepositoryImpl({
    required this.remoteDataSource,
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
        UnexpectedFailure(
          code: BusinessDocumentFailureCodes.unexpectedError,
        ),
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
      return FailureResult<BusinessDocumentReference>(
        failureMapper.fromStorage(error),
      );
    } catch (error) {
      return FailureResult<BusinessDocumentReference>(
        failureMapper.fromUnexpected(error),
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
      final bytes = await remoteDataSource.download(
        objectKey: reference.value,
      );
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
      return const Success<void>(null);
    } on StorageException catch (error) {
      return FailureResult<void>(failureMapper.fromStorage(error));
    } catch (error) {
      return FailureResult<void>(failureMapper.fromUnexpected(error));
    }
  }
}
