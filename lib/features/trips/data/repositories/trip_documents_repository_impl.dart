import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/documents/domain/entities/business_document_access.dart';
import '../../../../core/documents/domain/entities/business_document_file.dart';
import '../../../../core/documents/domain/entities/business_document_location.dart';
import '../../../../core/documents/domain/entities/business_document_reference.dart';
import '../../../../core/documents/domain/policies/business_document_file_policy.dart';
import '../../../../core/documents/domain/repositories/business_document_repository.dart';
import '../../../../core/errors/common_failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/trip_document.dart';
import '../../domain/entities/trip_document_kind.dart';
import '../../domain/failures/trip_document_failure_codes.dart';
import '../../domain/repositories/trip_documents_repository.dart';
import '../datasources/trip_documents_remote_data_source.dart';
import '../models/trip_document_model.dart';
import 'trip_document_repository_failure_mapper.dart';

final class TripDocumentsRepositoryImpl implements TripDocumentsRepository {
  static const String _documentScope = 'trips';

  final TripDocumentsRemoteDataSource remoteDataSource;
  final BusinessDocumentRepository businessDocumentRepository;
  final BusinessDocumentFilePolicy filePolicy;
  final TripDocumentRepositoryFailureMapper failureMapper;

  const TripDocumentsRepositoryImpl({
    required this.remoteDataSource,
    required this.businessDocumentRepository,
    this.filePolicy = const BusinessDocumentFilePolicy(),
    this.failureMapper = const TripDocumentRepositoryFailureMapper(),
  });

  @override
  Future<Result<List<TripDocument>>> getActiveDocuments({
    required String companyId,
    required String tripId,
  }) {
    return _guard(() async {
      final models = await remoteDataSource.getActiveDocuments(
        companyId: companyId,
        tripId: tripId,
      );
      return Success(models.map((model) => model.toEntity()).toList());
    });
  }

  @override
  Future<Result<TripDocument>> upload({
    required String companyId,
    required String tripId,
    required TripDocumentKind kind,
    required BusinessDocumentFile document,
  }) async {
    final uploadResult = await businessDocumentRepository.upload(
      location: BusinessDocumentLocation(
        companyId: companyId,
        scope: _documentScope,
        entityId: tripId,
        documentKind: kind.value,
      ),
      file: document,
    );
    final uploadFailure = uploadResult.failureOrNull;
    if (uploadFailure != null) return FailureResult(uploadFailure);

    final reference = uploadResult.dataOrNull;
    final mimeType = filePolicy.contentTypeFor(document);
    if (reference == null || mimeType == null) {
      return const FailureResult(
        UnexpectedFailure(code: TripDocumentFailureCodes.unexpectedError),
      );
    }

    try {
      final model = await remoteDataSource.createDocument(
        companyId: companyId,
        tripId: tripId,
        documentKind: kind.value,
        storageReference: reference.value,
        originalFileName: document.fileName.trim(),
        mimeType: mimeType,
        sizeBytes: document.sizeInBytes,
      );
      return Success(model.toEntity());
    } on PostgrestException catch (error) {
      final cleanupFailure = await _cleanupUploadedReference(
        companyId: companyId,
        reference: reference,
      );
      if (cleanupFailure != null) return FailureResult(cleanupFailure);
      return FailureResult(failureMapper.fromPostgrest(error));
    } catch (error) {
      final cleanupFailure = await _cleanupUploadedReference(
        companyId: companyId,
        reference: reference,
      );
      if (cleanupFailure != null) return FailureResult(cleanupFailure);
      return FailureResult(failureMapper.fromUnexpected(error));
    }
  }

  @override
  Future<Result<BusinessDocumentAccess>> createTemporaryAccess({
    required String companyId,
    required String tripId,
    required String documentId,
  }) async {
    final modelResult = await _getActiveDocument(
      companyId: companyId,
      tripId: tripId,
      documentId: documentId,
    );
    final failure = modelResult.failureOrNull;
    if (failure != null) return FailureResult(failure);

    final model = modelResult.dataOrNull;
    if (model == null) {
      return const FailureResult(
        UnexpectedFailure(code: TripDocumentFailureCodes.unexpectedError),
      );
    }

    return businessDocumentRepository.createTemporaryAccess(
      companyId: companyId,
      reference: BusinessDocumentReference(model.storageReference),
    );
  }

  @override
  Future<Result<Uint8List>> download({
    required String companyId,
    required String tripId,
    required String documentId,
  }) async {
    final modelResult = await _getActiveDocument(
      companyId: companyId,
      tripId: tripId,
      documentId: documentId,
    );
    final failure = modelResult.failureOrNull;
    if (failure != null) return FailureResult(failure);

    final model = modelResult.dataOrNull;
    if (model == null) {
      return const FailureResult(
        UnexpectedFailure(code: TripDocumentFailureCodes.unexpectedError),
      );
    }

    return businessDocumentRepository.download(
      companyId: companyId,
      reference: BusinessDocumentReference(model.storageReference),
    );
  }

  @override
  Future<Result<TripDocument>> replace({
    required String companyId,
    required String tripId,
    required String documentId,
    required BusinessDocumentFile document,
  }) async {
    final currentResult = await _getActiveDocument(
      companyId: companyId,
      tripId: tripId,
      documentId: documentId,
    );
    final currentFailure = currentResult.failureOrNull;
    if (currentFailure != null) return FailureResult(currentFailure);
    final current = currentResult.dataOrNull;
    if (current == null) {
      return const FailureResult(
        UnexpectedFailure(code: TripDocumentFailureCodes.unexpectedError),
      );
    }

    final uploadResult = await businessDocumentRepository.upload(
      location: BusinessDocumentLocation(
        companyId: companyId,
        scope: _documentScope,
        entityId: tripId,
        documentKind: current.kind.value,
      ),
      file: document,
    );
    final uploadFailure = uploadResult.failureOrNull;
    if (uploadFailure != null) return FailureResult(uploadFailure);

    final reference = uploadResult.dataOrNull;
    final mimeType = filePolicy.contentTypeFor(document);
    if (reference == null || mimeType == null) {
      return const FailureResult(
        UnexpectedFailure(code: TripDocumentFailureCodes.unexpectedError),
      );
    }

    try {
      final model = await remoteDataSource.replaceDocument(
        companyId: companyId,
        tripId: tripId,
        documentId: documentId,
        storageReference: reference.value,
        originalFileName: document.fileName.trim(),
        mimeType: mimeType,
        sizeBytes: document.sizeInBytes,
      );
      return Success(model.toEntity());
    } on PostgrestException catch (error) {
      final cleanupFailure = await _cleanupUploadedReference(
        companyId: companyId,
        reference: reference,
      );
      if (cleanupFailure != null) return FailureResult(cleanupFailure);
      return FailureResult(failureMapper.fromPostgrest(error));
    } catch (error) {
      final cleanupFailure = await _cleanupUploadedReference(
        companyId: companyId,
        reference: reference,
      );
      if (cleanupFailure != null) return FailureResult(cleanupFailure);
      return FailureResult(failureMapper.fromUnexpected(error));
    }
  }

  @override
  Future<Result<void>> remove({
    required String companyId,
    required String tripId,
    required String documentId,
  }) {
    return _guard(() async {
      await remoteDataSource.removeDocument(
        companyId: companyId,
        tripId: tripId,
        documentId: documentId,
      );
      return const Success<void>(null);
    });
  }

  Future<Result<TripDocumentModel>> _getActiveDocument({
    required String companyId,
    required String tripId,
    required String documentId,
  }) {
    return _guard(() async {
      final model = await remoteDataSource.getActiveDocumentById(
        companyId: companyId,
        tripId: tripId,
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
      code: TripDocumentFailureCodes.compensationCleanupFailed,
    );
  }
}
