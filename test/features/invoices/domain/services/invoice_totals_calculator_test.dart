import 'package:horus_system/core/domain/value_objects/currency_code.dart';
import 'package:horus_system/core/domain/value_objects/money.dart';
import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/invoices/domain/entities/invoice_totals.dart';
import 'package:horus_system/features/invoices/domain/services/invoice_totals_calculator.dart';
import 'package:test/test.dart';

void main() {
  const calculator = InvoiceTotalsCalculator();
  final aed = CurrencyCode.tryParse('AED')!;

  test('calculates subtotal, discount, VAT-ready tax, and grand total', () {
    final result = calculator.calculate(
      lineAmounts: [
        Money(minorUnits: 10000, currency: aed),
        Money(minorUnits: 5000, currency: aed),
      ],
      currency: aed,
      discountMinorUnits: 1000,
      taxRateBasisPoints: 500,
    );

    expect(result, isA<Success<InvoiceTotals>>());
    final totals = (result as Success<InvoiceTotals>).data;
    expect(totals.subtotal.minorUnits, 15000);
    expect(totals.discount.minorUnits, 1000);
    expect(totals.taxableAmount.minorUnits, 14000);
    expect(totals.taxAmount.minorUnits, 700);
    expect(totals.grandTotal.minorUnits, 14700);
  });

  test('rounds tax to the nearest minor unit', () {
    final result = calculator.calculate(
      lineAmounts: [Money(minorUnits: 101, currency: aed)],
      currency: aed,
      discountMinorUnits: 0,
      taxRateBasisPoints: 500,
    );

    final totals = (result as Success<InvoiceTotals>).data;
    expect(totals.taxAmount.minorUnits, 5);
  });

  test('rejects a discount greater than subtotal', () {
    final result = calculator.calculate(
      lineAmounts: [Money(minorUnits: 100, currency: aed)],
      currency: aed,
      discountMinorUnits: 101,
      taxRateBasisPoints: 0,
    );

    expect(
      result.failureOrNull?.code,
      FailureCodes.validationInvoiceDiscountExceedsSubtotal,
    );
  });

  test('rejects mixed currencies', () {
    final usd = CurrencyCode.tryParse('USD')!;
    final result = calculator.calculate(
      lineAmounts: [Money(minorUnits: 100, currency: usd)],
      currency: aed,
      discountMinorUnits: 0,
      taxRateBasisPoints: 0,
    );

    expect(
      result.failureOrNull?.code,
      FailureCodes.validationInvoiceCurrencyMismatch,
    );
  });
}
