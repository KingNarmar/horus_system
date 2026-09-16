import 'package:flutter/widgets.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/errors/failure_codes.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../../../core/localization/financial_readiness_localizations.dart';
import '../../../company/domain/failures/company_failure_codes.dart';
import '../../domain/failures/trip_failure_codes.dart';
import '../localization/trips_localizations_x.dart';

String tripsFailureMessage(BuildContext context, Failure failure) {
  final l10n = context.l10n;

  return switch (failure.code) {
    FailureCodes.validationTripQuantityNegative ||
    FailureCodes.validationTripQuantityInvalid ||
    FailureCodes.validationTripFreightPriceNegative ||
    FailureCodes.validationTripFreightRateInvalid ||
    FailureCodes.validationTripCommercialTermsIncomplete =>
      l10n.tripNumberInvalid,
    FailureCodes.validationTripCommercialAmountOverflow =>
      l10n.failureUnexpectedError,
    TripFailureCodes.financialCurrencyMismatch =>
      l10n.reportsCurrencyMismatchFailure,
    CompanyFailureCodes.conflictFinancialSettingsNotConfigured =>
      context.financialReadinessL10n.configurationRequired,
    _ => l10n.localizedErrorMessage(failure),
  };
}
