import 'package:flutter/widgets.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/errors/failure_codes.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../../../core/localization/financial_readiness_localizations.dart';
import '../../../company/domain/failures/company_failure_codes.dart';

String routesFailureMessage(BuildContext context, Failure failure) {
  final l10n = context.l10n;

  return switch (failure.code) {
    FailureCodes.validationRouteFreightRateInvalid =>
      l10n.defaultFreightPriceInvalid,
    CompanyFailureCodes.conflictFinancialSettingsNotConfigured =>
      context.financialReadinessL10n.configurationRequired,
    _ => l10n.localizedErrorMessage(failure),
  };
}
