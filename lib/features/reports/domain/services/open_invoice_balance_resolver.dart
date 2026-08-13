import '../../../../core/domain/value_objects/money.dart';
import '../../../../core/errors/common_failures.dart';
import '../../../../core/utils/result.dart';
import '../../../invoices/domain/entities/invoice.dart';
import '../../../invoices/domain/entities/invoice_customer_snapshot.dart';
import '../../../invoices/domain/entities/invoice_totals.dart';
import '../../../invoices/domain/value_objects/tax_rate.dart';
import '../../../payments/domain/entities/payment.dart';
import '../../../payments/domain/entities/payment_balance.dart';
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
    final zero = Money(minorUnits: 0, currency: invoice.total.currency);
    final taxRate = TaxRate.tryCreate(0);
    if (taxRate == null) {
      return const FailureResult(
        ConflictFailure(
          code: ReportsFailureCodes.conflictInvoiceBalanceInvalid,
        ),
      );
    }

    // PaymentBalanceCalculator intentionally reads only identity, status,
    // grand total and payment identity/amount. This private projection supplies
    // those authoritative report facts while keeping the canonical lifecycle
    // and overpayment rules in one place.
    final balanceInvoice = Invoice(
      id: invoice.invoiceId,
      companyId: companyId,
      customer: InvoiceCustomerSnapshot(
        companyId: companyId,
        customerId: invoice.customerId,
        name: invoice.customerName,
      ),
      status: invoice.status,
      currency: invoice.total.currency,
      lines: const [],
      totals: InvoiceTotals(
        subtotal: invoice.total,
        discount: zero,
        taxableAmount: invoice.total,
        taxRate: taxRate,
        taxAmount: zero,
        grandTotal: invoice.total,
      ),
      createdAt: invoice.issuedAt ?? invoice.issueDate,
      updatedAt: invoice.issuedAt ?? invoice.issueDate,
    );

    final balancePayments = payments.map(
      (payment) => Payment(
        id: payment.paymentId,
        companyId: companyId,
        invoiceId: payment.invoiceId,
        customerId: invoice.customerId,
        paymentMethodId: payment.paymentId,
        paymentDate: payment.paymentDate,
        amount: payment.amount,
        createdAt: payment.createdAt,
      ),
    );

    final result = _calculator.calculate(
      invoice: balanceInvoice,
      payments: balancePayments,
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
