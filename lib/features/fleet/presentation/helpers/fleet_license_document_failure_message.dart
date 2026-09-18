import 'package:flutter/widgets.dart';

import '../../../../core/documents/domain/failures/business_document_failure_codes.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../domain/failures/fleet_license_document_failure_codes.dart';

String fleetLicenseDocumentFailureMessage(
  BuildContext context,
  Failure failure,
) {
  final l10n = context.l10n;
  return switch (failure.code) {
    FleetLicenseDocumentFailureCodes.permissionView ||
    FleetLicenseDocumentFailureCodes.permissionManage =>
      l10n.fleetLicenseDocumentsPermissionFailure,
    FleetLicenseDocumentFailureCodes.conflictActiveDocumentExists ||
    FleetLicenseDocumentFailureCodes.conflictFileSide =>
      l10n.fleetLicenseDocumentFileSideConflictFailure,
    FleetLicenseDocumentFailureCodes.notFound =>
      l10n.fleetLicenseDocumentNotFoundFailure,
    FleetLicenseDocumentFailureCodes.fileNotFound =>
      l10n.fleetLicenseDocumentFileNotFoundFailure,
    FleetLicenseDocumentFailureCodes.compensationCleanupFailed =>
      l10n.fleetLicenseDocumentCleanupFailure,
    FleetLicenseDocumentFailureCodes.serverError =>
      l10n.fleetLicenseDocumentStorageFailure,
    BusinessDocumentFailureCodes.validationFileEmpty =>
      l10n.fleetLicenseDocumentFileEmptyFailure,
    BusinessDocumentFailureCodes.validationFileNameInvalid =>
      l10n.fleetLicenseDocumentFileNameInvalidFailure,
    BusinessDocumentFailureCodes.validationFileTypeUnsupported =>
      l10n.fleetLicenseDocumentFileTypeUnsupportedFailure,
    BusinessDocumentFailureCodes.validationFileTooLarge =>
      l10n.fleetLicenseDocumentFileTooLargeFailure,
    BusinessDocumentFailureCodes.permissionAccess ||
    BusinessDocumentFailureCodes.storageError =>
      l10n.fleetLicenseDocumentStorageFailure,
    _ => l10n.localizedErrorMessage(failure),
  };
}
