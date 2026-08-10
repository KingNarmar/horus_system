import '../../../../core/errors/failure.dart';
import '../../../../core/errors/failure_codes.dart';
import '../localization/payment_methods_localizations.dart';

String paymentMethodsFailureMessage(
  Failure failure,
  PaymentMethodsLocalizations l10n,
) {
  return switch (failure.code) {
    FailureCodes.permissionPaymentMethodsView => l10n.permissionViewFailure,
    FailureCodes.permissionPaymentMethodsManagement =>
      l10n.permissionManageFailure,
    FailureCodes.validationPaymentMethodNameRequired => l10n.nameRequired,
    FailureCodes.conflictPaymentMethodDuplicateName =>
      l10n.duplicateNameFailure,
    FailureCodes.paymentMethodNotFound => l10n.notFoundFailure,
    _ => l10n.genericFailure,
  };
}
