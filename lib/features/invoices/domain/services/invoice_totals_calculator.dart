import '../../../../core/domain/value_objects/currency_code.dart';
import '../../../../core/domain/value_objects/money.dart';
import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure_codes.dart';
import '../../../../core/utils/result.dart';
import '../entities/invoice_totals.dart';
import '../value_objects/tax_rate.dart';

final class InvoiceTotalsCalculator {
  const InvoiceTotalsCalculator();

  Result<InvoiceTotals> calculate({
    required List<Money> lineAmounts,
    required CurrencyCode currency,
    required int discountMinorUnits,
    required int taxRateBasisPoints,
  }) {
    if (lineAmounts.isEmpty) {
      return const FailureResult<InvoiceTotals>(
        ValidationFailure(code: FailureCodes.validationInvoiceTripsRequired),
      );
    }

    if (discountMinorUnits < 0) {
      return const FailureResult<InvoiceTotals>(
        ValidationFailure(code: FailureCodes.validationInvoiceDiscountNegative),
      );
    }

    final taxRate = TaxRate.tryCreate(taxRateBasisPoints);
    if (taxRate == null) {
      return const FailureResult<InvoiceTotals>(
        ValidationFailure(
          code: FailureCodes.validationInvoiceTaxRateOutOfRange,
        ),
      );
    }

    var subtotalMinorUnits = 0;
    for (final amount in lineAmounts) {
      if (amount.currency != currency) {
        return const FailureResult<InvoiceTotals>(
          ValidationFailure(
            code: FailureCodes.validationInvoiceCurrencyMismatch,
          ),
        );
      }
      if (!amount.isPositive) {
        return const FailureResult<InvoiceTotals>(
          ValidationFailure(
            code: FailureCodes.validationInvoiceLineAmountPositive,
          ),
        );
      }
      subtotalMinorUnits += amount.minorUnits;
    }

    if (discountMinorUnits > subtotalMinorUnits) {
      return const FailureResult<InvoiceTotals>(
        ValidationFailure(
          code: FailureCodes.validationInvoiceDiscountExceedsSubtotal,
        ),
      );
    }

    final taxableMinorUnits = subtotalMinorUnits - discountMinorUnits;
    final taxMinorUnits =
        (taxableMinorUnits * taxRate.basisPoints +
            TaxRate.maximumBasisPoints ~/ 2) ~/
        TaxRate.maximumBasisPoints;
    final grandTotalMinorUnits = taxableMinorUnits + taxMinorUnits;

    if (grandTotalMinorUnits <= 0) {
      return const FailureResult<InvoiceTotals>(
        ValidationFailure(code: FailureCodes.validationInvoiceTotalPositive),
      );
    }

    return Success<InvoiceTotals>(
      InvoiceTotals(
        subtotal: Money(minorUnits: subtotalMinorUnits, currency: currency),
        discount: Money(minorUnits: discountMinorUnits, currency: currency),
        taxableAmount: Money(minorUnits: taxableMinorUnits, currency: currency),
        taxRate: taxRate,
        taxAmount: Money(minorUnits: taxMinorUnits, currency: currency),
        grandTotal: Money(minorUnits: grandTotalMinorUnits, currency: currency),
      ),
    );
  }
}
