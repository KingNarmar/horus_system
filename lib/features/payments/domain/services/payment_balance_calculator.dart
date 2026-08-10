import '../../../../core/domain/value_objects/money.dart';
import '../../../../core/errors/common_failures.dart';
import '../../../../core/utils/result.dart';
import '../../../invoices/domain/entities/invoice.dart';
import '../../../invoices/domain/entities/invoice_status.dart';
import '../entities/payment.dart';
import '../entities/payment_balance.dart';
import '../failures/payment_failure_codes.dart';

final class PaymentBalanceCalculator {
  const PaymentBalanceCalculator();

  Result<PaymentBalance> calculate({
    required Invoice invoice,
    required Iterable<Payment> payments,
  }) {
    final total = invoice.totals.grandTotal;
    var paidMinorUnits = 0;

    for (final payment in payments) {
      if (payment.companyId != invoice.companyId ||
          payment.invoiceId != invoice.id ||
          !payment.amount.hasSameCurrency(total) ||
          !payment.amount.isPositive) {
        return const FailureResult(
          ConflictFailure(
            code: PaymentFailureCodes.conflictInvoiceBalanceInvalid,
          ),
        );
      }

      paidMinorUnits += payment.amount.minorUnits;
      if (paidMinorUnits > total.minorUnits) {
        return const FailureResult(
          ConflictFailure(
            code: PaymentFailureCodes.conflictInvoiceBalanceInvalid,
          ),
        );
      }
    }

    if (!_isStateConsistent(
      status: invoice.status,
      paidMinorUnits: paidMinorUnits,
      totalMinorUnits: total.minorUnits,
    )) {
      return const FailureResult(
        ConflictFailure(
          code: PaymentFailureCodes.conflictInvoiceBalanceInvalid,
        ),
      );
    }

    final paid = Money(minorUnits: paidMinorUnits, currency: total.currency);
    final remaining = Money(
      minorUnits: total.minorUnits - paidMinorUnits,
      currency: total.currency,
    );
    return Success(PaymentBalance(total: total, paid: paid, remaining: remaining));
  }

  bool _isStateConsistent({
    required InvoiceStatus status,
    required int paidMinorUnits,
    required int totalMinorUnits,
  }) {
    return switch (status) {
      InvoiceStatus.draft || InvoiceStatus.cancelled => paidMinorUnits == 0,
      InvoiceStatus.issued => paidMinorUnits == 0,
      InvoiceStatus.partiallyPaid =>
        paidMinorUnits > 0 && paidMinorUnits < totalMinorUnits,
      InvoiceStatus.paid => paidMinorUnits == totalMinorUnits,
    };
  }
}
