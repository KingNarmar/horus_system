import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/errors/failure_codes.dart';
import '../../../company/domain/failures/company_failure_codes.dart';
import '../../domain/failures/payment_failure_codes.dart';
import '../constants/payments_db_constants.dart';

abstract final class PaymentsFailureMapper {
  static Failure fromPostgrest(
    PostgrestException error, {
    required String permissionCode,
  }) {
    return switch (error.code) {
      PaymentsRpcErrorCodes.permissionDenied || '42501' => PermissionFailure(
        code: permissionCode,
      ),
      PaymentsRpcErrorCodes.invoiceNotFound => const NotFoundFailure(
        code: PaymentFailureCodes.invoiceNotFound,
      ),
      PaymentsRpcErrorCodes.invoiceStatusInvalid => const ConflictFailure(
        code: PaymentFailureCodes.conflictInvoiceStatusInvalid,
      ),
      PaymentsRpcErrorCodes.amountNotPositive => const ValidationFailure(
        code: PaymentFailureCodes.validationAmountPositive,
      ),
      PaymentsRpcErrorCodes.currencyMismatch => const ValidationFailure(
        code: PaymentFailureCodes.validationCurrencyMismatch,
      ),
      PaymentsRpcErrorCodes.paymentMethodNotFound => const NotFoundFailure(
        code: PaymentFailureCodes.paymentMethodNotFound,
      ),
      PaymentsRpcErrorCodes.paymentMethodInactive => const ConflictFailure(
        code: PaymentFailureCodes.conflictPaymentMethodInactive,
      ),
      PaymentsRpcErrorCodes.paymentDateRequired => const ValidationFailure(
        code: PaymentFailureCodes.validationDateRequired,
      ),
      PaymentsRpcErrorCodes.paymentDateBeforeInvoice => const ValidationFailure(
        code: PaymentFailureCodes.validationDateBeforeInvoice,
      ),
      PaymentsRpcErrorCodes.paymentDateFuture => const ValidationFailure(
        code: PaymentFailureCodes.validationDateFuture,
      ),
      PaymentsRpcErrorCodes.overpayment => const ConflictFailure(
        code: PaymentFailureCodes.conflictOverpayment,
      ),
      PaymentsRpcErrorCodes.invoiceBalanceInvalid => const ConflictFailure(
        code: PaymentFailureCodes.conflictInvoiceBalanceInvalid,
      ),
      PaymentsRpcErrorCodes.invoiceLinesRequired => const ConflictFailure(
        code: PaymentFailureCodes.conflictInvoiceLinesRequired,
      ),
      PaymentsRpcErrorCodes.tripStateInvalid => const ConflictFailure(
        code: PaymentFailureCodes.conflictTripStateInvalid,
      ),
      PaymentsRpcErrorCodes.companyNotFound => const NotFoundFailure(
        code: CompanyFailureCodes.notFound,
      ),
      PaymentsRpcErrorCodes.regionalSettingsNotConfigured =>
        const ConflictFailure(
          code: CompanyFailureCodes.conflictRegionalSettingsNotConfigured,
        ),
      PaymentsRpcErrorCodes.paymentMethodRequired => const ValidationFailure(
        code: PaymentFailureCodes.validationPaymentMethodIdRequired,
      ),
      PaymentsRpcErrorCodes.currencyRequired => const ValidationFailure(
        code: PaymentFailureCodes.validationCurrencyInvalid,
      ),
      _ => const ServerFailure(code: FailureCodes.serverError),
    };
  }
}
