import 'dart:typed_data';

import '../../../../core/documents/domain/entities/business_document_access.dart';
import '../../../../core/documents/domain/entities/business_document_file.dart';
import '../../../../core/domain/value_objects/business_date.dart';
import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/errors/failure_codes.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../entities/fleet_license_document.dart';
import '../entities/fleet_license_document_file.dart';
import '../entities/fleet_license_document_file_side.dart';
import '../entities/fleet_license_document_target.dart';
import '../failures/fleet_license_document_failure_codes.dart';
import '../policies/fleet_license_document_policy.dart';
import '../policies/fleet_license_expiry_policy.dart';
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

final class UploadFleetLicenseDocumentFileParams {
  final CurrentCompanyContext currentCompanyContext;
  final FleetLicenseDocumentTarget target;
  final FleetLicenseDocumentFileSide side;
  final BusinessDocumentFile file;
  final BusinessDate? newLicenseExpiryDate;
  final BusinessDate currentBusinessDate;

  const UploadFleetLicenseDocumentFileParams({
    required this.currentCompanyContext,
    required this.target,
    required this.side,
    required this.file,
    required this.currentBusinessDate,
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

final class FleetLicenseDocumentFileActionParams {
  final CurrentCompanyContext currentCompanyContext;
  final FleetLicenseDocumentTarget target;
  final FleetLicenseDocument document;
  final FleetLicenseDocumentFile file;

  const FleetLicenseDocumentFileActionParams({
    required this.currentCompanyContext,
    required this.target,
    required this.document,
    required this.file,
  });
}

final class ReplaceFleetLicenseDocumentFileParams {
  final CurrentCompanyContext currentCompanyContext;
  final FleetLicenseDocumentTarget target;
  final FleetLicenseDocument document;
  final FleetLicenseDocumentFile file;
  final BusinessDocumentFile replacement;
  final BusinessDate? newLicenseExpiryDate;
  final BusinessDate currentBusinessDate;

  const ReplaceFleetLicenseDocumentFileParams({
    required this.currentCompanyContext,
    required this.target,
    required this.document,
    required this.file,
    required this.replacement,
    required this.currentBusinessDate,
    this.newLicenseExpiryDate,
  });
}

final class GetFleetLicenseDocumentUseCase
    implements UseCase<FleetLicenseDocument?, GetFleetLicenseDocumentParams> {
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

final class UploadFleetLicenseDocumentFileUseCase
    implements
        UseCase<FleetLicenseDocument, UploadFleetLicenseDocumentFileParams> {
  final FleetLicenseDocumentsRepository _repository;
  final FleetLicenseDocumentPolicy _policy;

  const UploadFleetLicenseDocumentFileUseCase(
    this._repository, {
    FleetLicenseDocumentPolicy policy = const FleetLicenseDocumentPolicy(),
  }) : _policy = policy;

  @override
  Future<Result<FleetLicenseDocument>> call(
    UploadFleetLicenseDocumentFileParams params,
  ) async {
    final validation = _validateTarget(
      params.currentCompanyContext,
      params.target,
      manage: true,
    );
    if (validation != null) return FailureResult(validation);
    if (!FleetLicenseExpiryPolicy.isValid(
      licenseExpiryDate: params.newLicenseExpiryDate,
      currentBusinessDate: params.currentBusinessDate,
    )) {
      return const FailureResult(
        ValidationFailure(
          code: FailureCodes.validationFleetLicenseExpiryBeforeBusinessDate,
        ),
      );
    }

    final currentResult = await _repository.getActiveDocument(
      target: params.target,
    );
    final currentFailure = currentResult.failureOrNull;
    if (currentFailure != null) return FailureResult(currentFailure);

    final current = currentResult.dataOrNull;
    if (current == null) {
      if (!_policy.canCreateWithSide(params.side)) {
        return const FailureResult(
          ConflictFailure(
            code: FleetLicenseDocumentFailureCodes.conflictFileSide,
          ),
        );
      }
      return _repository.createWithFile(
        target: params.target,
        side: params.side,
        file: params.file,
        newLicenseExpiryDate: params.newLicenseExpiryDate,
      );
    }

    if (!_policy.canAddFile(current, params.side)) {
      return const FailureResult(
        ConflictFailure(
          code: FleetLicenseDocumentFailureCodes.conflictFileSide,
        ),
      );
    }

    return _repository.addFile(
      target: params.target,
      documentId: current.id,
      side: params.side,
      file: params.file,
      newLicenseExpiryDate: params.newLicenseExpiryDate,
    );
  }
}

final class GetFleetLicenseDocumentFileAccessUseCase
    implements
        UseCase<BusinessDocumentAccess, FleetLicenseDocumentFileActionParams> {
  final FleetLicenseDocumentsRepository _repository;

  const GetFleetLicenseDocumentFileAccessUseCase(this._repository);

  @override
  Future<Result<BusinessDocumentAccess>> call(
    FleetLicenseDocumentFileActionParams params,
  ) {
    final validation = _validateFileAction(params, manage: false);
    if (validation != null) return Future.value(FailureResult(validation));
    return _repository.createTemporaryAccess(
      target: params.target,
      documentId: params.document.id,
      fileId: params.file.id,
    );
  }
}

final class DownloadFleetLicenseDocumentFileUseCase
    implements UseCase<Uint8List, FleetLicenseDocumentFileActionParams> {
  final FleetLicenseDocumentsRepository _repository;

  const DownloadFleetLicenseDocumentFileUseCase(this._repository);

  @override
  Future<Result<Uint8List>> call(FleetLicenseDocumentFileActionParams params) {
    final validation = _validateFileAction(params, manage: false);
    if (validation != null) return Future.value(FailureResult(validation));
    return _repository.download(
      target: params.target,
      documentId: params.document.id,
      fileId: params.file.id,
    );
  }
}

final class ReplaceFleetLicenseDocumentFileUseCase
    implements
        UseCase<FleetLicenseDocument, ReplaceFleetLicenseDocumentFileParams> {
  final FleetLicenseDocumentsRepository _repository;
  final FleetLicenseDocumentPolicy _policy;

  const ReplaceFleetLicenseDocumentFileUseCase(
    this._repository, {
    FleetLicenseDocumentPolicy policy = const FleetLicenseDocumentPolicy(),
  }) : _policy = policy;

  @override
  Future<Result<FleetLicenseDocument>> call(
    ReplaceFleetLicenseDocumentFileParams params,
  ) {
    final action = FleetLicenseDocumentFileActionParams(
      currentCompanyContext: params.currentCompanyContext,
      target: params.target,
      document: params.document,
      file: params.file,
    );
    final validation = _validateFileAction(action, manage: true);
    if (validation != null) return Future.value(FailureResult(validation));
    if (!FleetLicenseExpiryPolicy.isValid(
      licenseExpiryDate: params.newLicenseExpiryDate,
      currentBusinessDate: params.currentBusinessDate,
    )) {
      return Future.value(
        const FailureResult(
          ValidationFailure(
            code: FailureCodes.validationFleetLicenseExpiryBeforeBusinessDate,
          ),
        ),
      );
    }
    if (!_policy.canReplaceFile(params.document, params.file)) {
      return Future.value(
        const FailureResult(
          NotFoundFailure(code: FleetLicenseDocumentFailureCodes.fileNotFound),
        ),
      );
    }

    return _repository.replaceFile(
      target: params.target,
      documentId: params.document.id,
      fileId: params.file.id,
      side: params.file.side,
      replacement: params.replacement,
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
    if (!_policy.canRemove(params.document)) {
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

Failure? _validateFileAction(
  FleetLicenseDocumentFileActionParams params, {
  required bool manage,
}) {
  final documentFailure = _validateDocumentAction(
    FleetLicenseDocumentActionParams(
      currentCompanyContext: params.currentCompanyContext,
      target: params.target,
      document: params.document,
    ),
    manage: manage,
  );
  if (documentFailure != null) return documentFailure;

  final file = params.file;
  if (file.companyId != params.target.companyId ||
      file.licenseDocumentId != params.document.id ||
      !file.isActive) {
    return PermissionFailure(
      code: manage
          ? FleetLicenseDocumentFailureCodes.permissionManage
          : FleetLicenseDocumentFailureCodes.permissionView,
    );
  }
  if (file.id.trim().isEmpty) {
    return const ValidationFailure(
      code: FleetLicenseDocumentFailureCodes.validationFileIdRequired,
    );
  }
  return null;
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
