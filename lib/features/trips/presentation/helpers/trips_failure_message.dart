import 'package:flutter/widgets.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/documents/domain/failures/business_document_failure_codes.dart';
import '../../../../core/errors/failure_codes.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../../../core/localization/financial_readiness_localizations.dart';
import '../../../company/domain/failures/company_failure_codes.dart';
import '../../domain/failures/trip_document_failure_codes.dart';
import '../../domain/failures/trip_failure_codes.dart';

String tripsFailureMessage(BuildContext context, Failure failure) {
  final l10n = context.l10n;

  return switch (failure.code) {
    FailureCodes.validationTripQuantityNegative ||
    FailureCodes.validationTripQuantityInvalid ||
    FailureCodes.validationTripFreightPriceNegative ||
    FailureCodes.validationTripFreightRateInvalid ||
    FailureCodes.validationTripCommercialTermsIncomplete =>
      l10n.tripNumberInvalid,
    FailureCodes.validationTripDeliveryBeforeLoading =>
      l10n.tripDeliveryBeforeLoadingInvalid,
    FailureCodes.permissionTripsManagement =>
      l10n.tripManagementPermissionFailure,
    FailureCodes.permissionTripStatusUpdate => l10n.tripStatusPermissionFailure,
    TripFailureCodes.notFound => l10n.tripNotFoundFailure,
    TripDocumentFailureCodes.permissionView ||
    TripDocumentFailureCodes.permissionManage =>
      l10n.tripDocumentsPermissionFailure,
    TripDocumentFailureCodes.conflictMaxActiveDocuments =>
      l10n.tripDocumentsMaxActiveFailure,
    TripDocumentFailureCodes.conflictEvidenceRequired =>
      l10n.tripDocumentsEvidenceRequiredFailure,
    TripDocumentFailureCodes.notFound => l10n.tripDocumentNotFoundFailure,
    TripDocumentFailureCodes.compensationCleanupFailed =>
      l10n.tripDocumentCleanupFailure,
    TripDocumentFailureCodes.serverError =>
      l10n.tripDocumentStorageFailure,
    BusinessDocumentFailureCodes.validationFileEmpty =>
      l10n.tripDocumentFileEmptyFailure,
    BusinessDocumentFailureCodes.validationFileNameInvalid =>
      l10n.tripDocumentFileNameInvalidFailure,
    BusinessDocumentFailureCodes.validationFileTypeUnsupported =>
      l10n.tripDocumentFileTypeUnsupportedFailure,
    BusinessDocumentFailureCodes.validationFileTooLarge =>
      l10n.tripDocumentFileTooLargeFailure,
    BusinessDocumentFailureCodes.storageError =>
      l10n.tripDocumentStorageFailure,
    FailureCodes.validationTripCommercialAmountOverflow =>
      l10n.failureUnexpectedError,
    TripFailureCodes.financialCurrencyMismatch =>
      context.financialReadinessL10n.currencyMismatch,
    CompanyFailureCodes.conflictFinancialSettingsNotConfigured =>
      context.financialReadinessL10n.configurationRequired,
    _ => l10n.localizedErrorMessage(failure),
  };
}
