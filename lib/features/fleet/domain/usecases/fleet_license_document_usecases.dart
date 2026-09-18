import 'dart:typed_data';

import '../../../../core/documents/domain/entities/business_document_access.dart';
import '../../../../core/documents/domain/entities/business_document_file.dart';
import '../../../../core/domain/value_objects/business_date.dart';
import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../entities/fleet_license_document.dart';
import '../entities/fleet_license_document_target.dart';
import '../failures/fleet_license_document_failure_codes.dart';
import '../policies/fleet_license_document_policy.dart';
import '../policies/fleet_permission_policy.dart';
import '../repositories/fleet_license_documents_repository.dart';

final class GetFleetLicenseDocumentParams {
  final CurrentCompanyContext currentCompanyContext;
  final FleetLicenseDocumentTarget target;

  const GetFleetLicenseDocumentParams({
    required this.currentCompanyContext,
    required this.target,
  });
}

final class UploadFleetLicenseDocumentParams {
  final CurrentCompanyContext currentCompanyContext;
  final FleetLicenseDocumentTarget target;
  final BusinessDocumentFile document;
  final BusinessDate? newLicenseExpiryDate;

  const UploadFleetLicenseDocumentParams({
    required this.currentCompanyContext,
    required this.target,
    required this.document,
    this.newLicenseExpiryDate,
  });
}

final class FleetLicenseDocumentActionParams {
  final CurrentCompanyContext currentCompanyContext;
  final FleetLicenseDocumentTarget target;
  final FleetLicenseDocument document;

  const FleetLicenseDocumentActionParams({
    required this.currentCompanyContext,
    required this.target,
    required this.document,
  });
}

final class ReplaceFleetLicenseDocumentParams {
  final CurrentCompanyContext currentCompanyContext;
  final FleetLicenseDocumentTarget target;
  final FleetLicenseDocument document;
  final BusinessDocumentFile replacement;
  final BusinessDate? newLicenseExpiryDate;

  const ReplaceFleetLicenseDocumentParams({
    required this.currentCompanyContext,
    required this.target,
    required this.document,
    required this.replacement,
    this.newLicenseExpiryDate,
  });
}

final class GetFleetLicenseDocumentUseCase
    implements
        UseCase<FleetLicenseDocument?, GetFleetLicenseDocumentParams> {
  final FleetLicenseDocumentsRepository _repository;

  const GetFleetLicenseDocumentUseCase(this._repository);

  @override
  Future<Result<FleetLicenseDocument?>> call(
    GetFleetLicenseDocumentParams params,
  ) {
    final validation = _validateTarget(
      params.currentCompanyContext,
      params.target,
      manage: false,
    );
    if (validation != null) {
      return Future.value(FailureResult(validation));
    }
    return _repository.getActiveDocument(target: params.target);
  }
}

final class UploadFleetLicenseDocumentUseCase
    implements
        UseCase<FleetLicenseDocument, UploadFleetLicenseDocumentParams> {
  final FleetLicenseDocumentsRepository _repository;
  final FleetLicenseDocumentPolicy _policy;

  const UploadFleetLicenseDocumentUseCase(
    this._repository, {
    FleetLicenseDocumentPolicy policy = const FleetLicenseDocumentPolicy(),
  }) : _policy = policy;

  @override
  Future<Result<FleetLicenseDocument>> call(
    UploadFleetLicenseDocumentParams params,
  ) async {
    final validation = _validateTarget(
      params.currentCompanyContext,
      params.target,
      manage: true,
    );
    if (validation != null) return FailureResult(validation);

    final currentResult = await _repository.getActiveDocument(
      target: params.target,
    );
    if (currentResult is FailureResult<FleetLicenseDocument?>) {
      return FailureResult(currentResult.failure);
    }
    final current = (currentResult as Success<FleetLicenseDocument?>).data;
    if (!_policy.canUpload(current)) {
      return const FailureResult(
        ConflictFailure(
          code:
              FleetLicenseDocumentFailureCodes.conflictActiveDocumentExists,
        ),
      );
    }

    return _repository.upload(
      target: params.target,
      document: params.document,
      newLicenseExpiryDate: params.newLicenseExpiryDate,
    );
  }
}

final class GetFleetLicenseDocumentAccessUseCase
    implements
        UseCase<BusinessDocumentAccess, FleetLicenseDocumentActionParams> {
  final FleetLicenseDocumentsRepository _repository;

  const GetFleetLicenseDocumentAccessUseCase(this._repository);

  @override
  Future<Result<BusinessDocumentAccess>> call(
    FleetLicenseDocumentActionParams params,
  ) {
    final validation = _validateDocumentAction(params, manage: false);
    if (validation != null) return Future.value(FailureResult(validation));
    return _repository.createTemporaryAccess(
      target: params.target,
      documentId: params.document.id,
    );
  }
}

final class DownloadFleetLicenseDocumentUseCase
    implements UseCase<Uint8List, FleetLicenseDocumentActionParams> {
  final FleetLicenseDocumentsRepository _repository;

  const DownloadFleetLicenseDocumentUseCase(this._repository);

  @override
  Future<Result<Uint8List>> call(FleetLicenseDocumentActionParams params) {
    final validation = _validateDocumentAction(params, manage: false);
    if (validation != null) return Future.value(FailureResult(validation));
    return _repository.download(
      target: params.target,
      documentId: params.document.id,
    );
  }
}

final class ReplaceFleetLicenseDocumentUseCase
    implements
        UseCase<FleetLicenseDocument, ReplaceFleetLicenseDocumentParams> {
  final FleetLicenseDocumentsRepository _repository;
  final FleetLicenseDocumentPolicy _policy;

  const ReplaceFleetLicenseDocumentUseCase(
    this._repository, {
    FleetLicenseDocumentPolicy policy = const FleetLicenseDocumentPolicy(),
  }) : _policy = policy;

  @override
  Future<Result<FleetLicenseDocument>> call(
    ReplaceFleetLicenseDocumentParams params,
  ) {
    final action = FleetLicenseDocumentActionParams(
      currentCompanyContext: params.currentCompanyContext,
      target: params.target,
      document: params.document,
    );
    final validation = _validateDocumentAction(action, manage: true);
    if (validation != null) return Future.value(FailureResult(validation));
    if (!_policy.canMutate(params.document)) {
      return Future.value(
        const FailureResult(
          NotFoundFailure(code: FleetLicenseDocumentFailureCodes.notFound),
        ),
      );
    }
    return _repository.replace(
      target: params.target,
      documentId: params.document.id,
      document: params.replacement,
      newLicenseExpiryDate: params.newLicenseExpiryDate,
    );
  }
}

final class RemoveFleetLicenseDocumentUseCase
    implements UseCase<void, FleetLicenseDocumentActionParams> {
  final FleetLicenseDocumentsRepository _repository;
  final FleetLicenseDocumentPolicy _policy;

  const RemoveFleetLicenseDocumentUseCase(
    this._repository, {
    FleetLicenseDocumentPolicy policy = const FleetLicenseDocumentPolicy(),
  }) : _policy = policy;

  @override
  Future<Result<void>> call(FleetLicenseDocumentActionParams params) {
    final validation = _validateDocumentAction(params, manage: true);
    if (validation != null) return Future.value(FailureResult(validation));
    if (!_policy.canMutate(params.document)) {
      return Future.value(
        const FailureResult(
          NotFoundFailure(code: FleetLicenseDocumentFailureCodes.notFound),
        ),
      );
    }
    return _repository.remove(
      target: params.target,
      documentId: params.document.id,
    );
  }
}

Failure? _validateDocumentAction(
  FleetLicenseDocumentActionParams params, {
  required bool manage,
}) {
  final targetFailure = _validateTarget(
    params.currentCompanyContext,
    params.target,
    manage: manage,
  );
  if (targetFailure != null) return targetFailure;

  final document = params.document;
  if (document.companyId != params.target.companyId ||
      document.assetType != params.target.assetType ||
      document.assetId != params.target.assetId ||
      !document.isActive) {
    return PermissionFailure(
      code: manage
          ? FleetLicenseDocumentFailureCodes.permissionManage
          : FleetLicenseDocumentFailureCodes.permissionView,
    );
  }
  if (document.id.trim().isEmpty) {
    return const ValidationFailure(
      code: FleetLicenseDocumentFailureCodes.validationDocumentIdRequired,
    );
  }
  return null;
}

Failure? _validateTarget(
  CurrentCompanyContext context,
  FleetLicenseDocumentTarget target, {
  required bool manage,
}) {
  final roleAllowed = manage
      ? FleetPermissionPolicy.canManageFleet(context.role)
      : FleetPermissionPolicy.canViewFleet(context.role);
  if (!roleAllowed || target.companyId != context.companyId) {
    return PermissionFailure(
      code: manage
          ? FleetLicenseDocumentFailureCodes.permissionManage
          : FleetLicenseDocumentFailureCodes.permissionView,
    );
  }
  if (target.assetId.trim().isEmpty) {
    return const ValidationFailure(
      code: FleetLicenseDocumentFailureCodes.validationAssetIdRequired,
    );
  }
  return null;
}
