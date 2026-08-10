import 'package:flutter/widgets.dart';

import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../../company/domain/failures/company_failure_codes.dart';
import '../../domain/failures/payment_failure_codes.dart';
import '../localization/payments_localizations.dart';

String paymentsFailureMessage(BuildContext context, Failure failure) {
  final strings = context.paymentsL10n;

  return switch (failure.code) {
    PaymentFailureCodes.permissionView => strings.permissionViewFailure,
    PaymentFailureCodes.permissionManage => strings.permissionManageFailure,
    PaymentFailureCodes.validationInvoiceIdRequired ||
    PaymentFailureCodes.invoiceNotFound => strings.invoiceNotFoundFailure,
    PaymentFailureCodes.validationPaymentMethodIdRequired =>
      strings.paymentMethodRequired,
    PaymentFailureCodes.paymentMethodNotFound => strings.methodNotFoundFailure,
    PaymentFailureCodes.conflictInvoiceStatusInvalid =>
      strings.invoiceStatusFailure,
    PaymentFailureCodes.validationAmountInvalid => strings.amountInvalidFailure,
    PaymentFailureCodes.validationAmountPositive =>
      strings.amountPositiveFailure,
    PaymentFailureCodes.validationCurrencyInvalid =>
      strings.currencyInvalidFailure,
    PaymentFailureCodes.validationCurrencyMismatch =>
      strings.currencyMismatchFailure,
    PaymentFailureCodes.validationDateRequired => strings.dateRequired,
    PaymentFailureCodes.validationDateBeforeInvoice =>
      strings.dateBeforeInvoiceFailure,
    PaymentFailureCodes.validationDateFuture => strings.dateFutureFailure,
    PaymentFailureCodes.conflictPaymentMethodInactive =>
      strings.inactiveMethodFailure,
    PaymentFailureCodes.conflictOverpayment => strings.overpaymentFailure,
    PaymentFailureCodes.conflictInvoiceBalanceInvalid =>
      strings.balanceChangedFailure,
    PaymentFailureCodes.conflictInvoiceLinesRequired =>
      strings.invoiceLinesFailure,
    PaymentFailureCodes.conflictTripStateInvalid => strings.tripStateFailure,
    CompanyFailureCodes.conflictRegionalSettingsNotConfigured =>
      strings.regionalSettingsFailure,
    _ => _safeFallback(context, failure, strings),
  };
}

String _safeFallback(
  BuildContext context,
  Failure failure,
  PaymentsLocalizations strings,
) {
  if (failure is ServerFailure || failure is UnexpectedFailure) {
    return context.l10n.localizedErrorMessage(failure);
  }
  if (failure is PermissionFailure) return strings.permissionManageFailure;
  if (failure is NotFoundFailure) return strings.invoiceNotFoundFailure;
  if (failure is ConflictFailure) return strings.balanceChangedFailure;
  if (failure is ValidationFailure) return strings.registrationFailed;
  return strings.loadFailed;
}
