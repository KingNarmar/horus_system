import '../../../../core/domain/value_objects/money.dart';
import '../../../../core/errors/common_failures.dart';
import '../../../../core/utils/result.dart';
import '../../../payments/domain/entities/payment_balance.dart';
import '../../../payments/domain/entities/payment_balance_snapshot.dart';
import '../../../payments/domain/services/payment_balance_calculator.dart';
import '../entities/open_invoices_report.dart';
import '../failures/reports_failure_codes.dart';

final class OpenInvoiceBalanceResolver {
  final PaymentBalanceCalculator _calculator;

  const OpenInvoiceBalanceResolver({
    PaymentBalanceCalculator calculator = const PaymentBalanceCalculator(),
  }) : _calculator = calculator;

  Result<PaymentBalance> calculate({
    required String companyId,
    required OpenInvoiceSourceInvoice invoice,
    required Iterable<OpenInvoiceSourcePayment> payments,
  }) {
    final result = _calculator.calculateSnapshot(
      invoice: PaymentBalanceInvoiceSnapshot(
        companyId: companyId,
        invoiceId: invoice.invoiceId,
        status: invoice.status,
        total: invoice.total,
      ),
      payments: payments.map(
        (payment) => PaymentBalancePaymentSnapshot(
          companyId: companyId,
          invoiceId: payment.invoiceId,
          amount: payment.amount,
        ),
      ),
    );

    return result.when(
      success: Success<PaymentBalance>.new,
      failure: (_) => const FailureResult(
        ConflictFailure(
          code: ReportsFailureCodes.conflictInvoiceBalanceInvalid,
        ),
      ),
    );
  }
}
