import 'dart:typed_data';

import '../../../../core/documents/domain/entities/business_document_access.dart';
import '../../../../core/documents/domain/entities/business_document_file.dart';
import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/errors/failure_codes.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../entities/trip_document.dart';
import '../entities/trip_document_kind.dart';
import '../entities/trip_entity.dart';
import '../failures/trip_document_failure_codes.dart';
import '../policies/trip_evidence_policy.dart';
import '../policies/trips_permission_policy.dart';
import '../repositories/trip_documents_repository.dart';

final class GetTripDocumentsParams {
  final CurrentCompanyContext currentCompanyContext;
  final String tripId;

  const GetTripDocumentsParams({
    required this.currentCompanyContext,
    required this.tripId,
  });
}

final class UploadTripDocumentParams {
  final CurrentCompanyContext currentCompanyContext;
  final String tripId;
  final TripDocumentKind kind;
  final BusinessDocumentFile document;

  const UploadTripDocumentParams({
    required this.currentCompanyContext,
    required this.tripId,
    required this.kind,
    required this.document,
  });
}

final class TripDocumentActionParams {
  final CurrentCompanyContext currentCompanyContext;
  final TripDocument document;

  const TripDocumentActionParams({
    required this.currentCompanyContext,
    required this.document,
  });
}

final class RemoveTripDocumentParams {
  final CurrentCompanyContext currentCompanyContext;
  final TripEntity trip;
  final TripDocument document;

  const RemoveTripDocumentParams({
    required this.currentCompanyContext,
    required this.trip,
    required this.document,
  });
}

final class ReplaceTripDocumentParams {
  final CurrentCompanyContext currentCompanyContext;
  final TripDocument document;
  final BusinessDocumentFile replacement;

  const ReplaceTripDocumentParams({
    required this.currentCompanyContext,
    required this.document,
    required this.replacement,
  });
}

final class GetTripDocumentsUseCase
    implements UseCase<List<TripDocument>, GetTripDocumentsParams> {
  final TripDocumentsRepository _repository;

  const GetTripDocumentsUseCase(this._repository);

  @override
  Future<Result<List<TripDocument>>> call(GetTripDocumentsParams params) {
    final context = params.currentCompanyContext;
    if (!TripsPermissionPolicy.canViewTripDocuments(context.role)) {
      return Future.value(
        const FailureResult(
          PermissionFailure(code: TripDocumentFailureCodes.permissionView),
        ),
      );
    }

    final tripId = params.tripId.trim();
    if (tripId.isEmpty) {
      return Future.value(
        const FailureResult(
          ValidationFailure(code: FailureCodes.validationTripIdRequired),
        ),
      );
    }

    return _repository.getActiveDocuments(
      companyId: context.companyId,
      tripId: tripId,
    );
  }
}

final class UploadTripDocumentUseCase
    implements UseCase<TripDocument, UploadTripDocumentParams> {
  final TripDocumentsRepository _repository;
  final TripEvidencePolicy _evidencePolicy;

  const UploadTripDocumentUseCase(
    this._repository, {
    TripEvidencePolicy evidencePolicy = const TripEvidencePolicy(),
  }) : _evidencePolicy = evidencePolicy;

  @override
  Future<Result<TripDocument>> call(UploadTripDocumentParams params) async {
    final context = params.currentCompanyContext;
    if (!TripsPermissionPolicy.canManageTripDocuments(context.role)) {
      return const FailureResult(
        PermissionFailure(code: TripDocumentFailureCodes.permissionManage),
      );
    }

    final tripId = params.tripId.trim();
    if (tripId.isEmpty) {
      return const FailureResult(
        ValidationFailure(code: FailureCodes.validationTripIdRequired),
      );
    }

    final currentResult = await _repository.getActiveDocuments(
      companyId: context.companyId,
      tripId: tripId,
    );
    if (currentResult is FailureResult<List<TripDocument>>) {
      return FailureResult(currentResult.failure);
    }

    if (!_evidencePolicy.canUpload(
      (currentResult as Success<List<TripDocument>>).data,
    )) {
      return const FailureResult(
        ConflictFailure(
          code: TripDocumentFailureCodes.conflictMaxActiveDocuments,
        ),
      );
    }

    return _repository.upload(
      companyId: context.companyId,
      tripId: tripId,
      kind: params.kind,
      document: params.document,
    );
  }
}

final class GetTripDocumentAccessUseCase
    implements UseCase<BusinessDocumentAccess, TripDocumentActionParams> {
  final TripDocumentsRepository _repository;

  const GetTripDocumentAccessUseCase(this._repository);

  @override
  Future<Result<BusinessDocumentAccess>> call(TripDocumentActionParams params) {
    final failure = _validateDocumentAccess(params, manage: false);
    if (failure != null) return Future.value(FailureResult(failure));

    return _repository.createTemporaryAccess(
      companyId: params.currentCompanyContext.companyId,
      tripId: params.document.tripId,
      documentId: params.document.id,
    );
  }
}

final class DownloadTripDocumentUseCase
    implements UseCase<Uint8List, TripDocumentActionParams> {
  final TripDocumentsRepository _repository;

  const DownloadTripDocumentUseCase(this._repository);

  @override
  Future<Result<Uint8List>> call(TripDocumentActionParams params) {
    final failure = _validateDocumentAccess(params, manage: false);
    if (failure != null) return Future.value(FailureResult(failure));

    return _repository.download(
      companyId: params.currentCompanyContext.companyId,
      tripId: params.document.tripId,
      documentId: params.document.id,
    );
  }
}

final class RemoveTripDocumentUseCase
    implements UseCase<void, RemoveTripDocumentParams> {
  final TripDocumentsRepository _repository;
  final TripEvidencePolicy _evidencePolicy;

  const RemoveTripDocumentUseCase(
    this._repository, {
    TripEvidencePolicy evidencePolicy = const TripEvidencePolicy(),
  }) : _evidencePolicy = evidencePolicy;

  @override
  Future<Result<void>> call(RemoveTripDocumentParams params) async {
    final context = params.currentCompanyContext;
    if (!TripsPermissionPolicy.canManageTripDocuments(context.role)) {
      return const FailureResult(
        PermissionFailure(code: TripDocumentFailureCodes.permissionManage),
      );
    }

    if (params.trip.companyId != context.companyId ||
        params.document.companyId != context.companyId ||
        params.document.tripId != params.trip.id ||
        !params.document.isActive) {
      return const FailureResult(
        PermissionFailure(code: TripDocumentFailureCodes.permissionManage),
      );
    }

    final currentResult = await _repository.getActiveDocuments(
      companyId: context.companyId,
      tripId: params.trip.id,
    );
    if (currentResult is FailureResult<List<TripDocument>>) {
      return FailureResult(currentResult.failure);
    }

    if (!_evidencePolicy.canRemove(
      currentStatus: params.trip.status,
      documents: (currentResult as Success<List<TripDocument>>).data,
      documentId: params.document.id,
    )) {
      return const FailureResult(
        ConflictFailure(
          code: TripDocumentFailureCodes.conflictEvidenceRequired,
        ),
      );
    }

    return _repository.remove(
      companyId: context.companyId,
      tripId: params.trip.id,
      documentId: params.document.id,
    );
  }
}

final class ReplaceTripDocumentUseCase
    implements UseCase<TripDocument, ReplaceTripDocumentParams> {
  final TripDocumentsRepository _repository;

  const ReplaceTripDocumentUseCase(this._repository);

  @override
  Future<Result<TripDocument>> call(ReplaceTripDocumentParams params) {
    final context = params.currentCompanyContext;
    if (!TripsPermissionPolicy.canManageTripDocuments(context.role) ||
        params.document.companyId != context.companyId ||
        !params.document.isActive) {
      return Future.value(
        const FailureResult(
          PermissionFailure(code: TripDocumentFailureCodes.permissionManage),
        ),
      );
    }

    return _repository.replace(
      companyId: context.companyId,
      tripId: params.document.tripId,
      documentId: params.document.id,
      document: params.replacement,
    );
  }
}

Failure? _validateDocumentAccess(
  TripDocumentActionParams params, {
  required bool manage,
}) {
  final context = params.currentCompanyContext;
  final roleAllowed = manage
      ? TripsPermissionPolicy.canManageTripDocuments(context.role)
      : TripsPermissionPolicy.canViewTripDocuments(context.role);

  if (!roleAllowed ||
      params.document.companyId != context.companyId ||
      !params.document.isActive) {
    return PermissionFailure(
      code: manage
          ? TripDocumentFailureCodes.permissionManage
          : TripDocumentFailureCodes.permissionView,
    );
  }

  if (params.document.id.trim().isEmpty) {
    return const ValidationFailure(
      code: TripDocumentFailureCodes.validationDocumentIdRequired,
    );
  }

  return null;
}
