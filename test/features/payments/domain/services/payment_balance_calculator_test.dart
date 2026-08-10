import 'package:horus_system/core/domain/value_objects/currency_code.dart';
import 'package:horus_system/core/domain/value_objects/money.dart';
import 'package:horus_system/features/invoices/domain/entities/invoice.dart';
import 'package:horus_system/features/invoices/domain/entities/invoice_customer_snapshot.dart';
import 'package:horus_system/features/invoices/domain/entities/invoice_status.dart';
import 'package:horus_system/features/invoices/domain/entities/invoice_totals.dart';
import 'package:horus_system/features/invoices/domain/entities/invoice_trip_line.dart';
import 'package:horus_system/features/invoices/domain/value_objects/tax_rate.dart';
import 'package:horus_system/features/payments/domain/entities/payment.dart';
import 'package:horus_system/features/payments/domain/failures/payment_failure_codes.dart';
import 'package:horus_system/features/payments/domain/services/payment_balance_calculator.dart';
import 'package:test/test.dart';

void main() {
  const calculator = PaymentBalanceCalculator();

  test('calculates partial balance from minor units', () {
    final result = calculator.calculate(
      invoice: _invoice(status: InvoiceStatus.partiallyPaid),
      payments: [_payment(amountMinorUnits: 40000)],
    );

    expect(result.failureOrNull, isNull);
    final balance = result.dataOrNull!;
    expect(balance.total.minorUnits, 120000);
    expect(balance.paid.minorUnits, 40000);
    expect(balance.remaining.minorUnits, 80000);
  });

  test('paid invoice requires payments to equal invoice total', () {
    final result = calculator.calculate(
      invoice: _invoice(status: InvoiceStatus.paid),
      payments: [_payment(amountMinorUnits: 40000)],
    );

    expect(
      result.failureOrNull?.code,
      PaymentFailureCodes.conflictInvoiceBalanceInvalid,
    );
  });

  test('issued invoice rejects unexpected persisted payments', () {
    final result = calculator.calculate(
      invoice: _invoice(status: InvoiceStatus.issued),
      payments: [_payment(amountMinorUnits: 1000)],
    );

    expect(
      result.failureOrNull?.code,
      PaymentFailureCodes.conflictInvoiceBalanceInvalid,
    );
  });

  test('rejects cross-invoice and cross-currency payment data', () {
    final crossInvoice = calculator.calculate(
      invoice: _invoice(status: InvoiceStatus.partiallyPaid),
      payments: [_payment(invoiceId: 'invoice-2', amountMinorUnits: 40000)],
    );
    final crossCurrency = calculator.calculate(
      invoice: _invoice(status: InvoiceStatus.partiallyPaid),
      payments: [
        _payment(
          amountMinorUnits: 40000,
          currency: CurrencyCode.tryParse('USD')!,
        ),
      ],
    );

    expect(
      crossInvoice.failureOrNull?.code,
      PaymentFailureCodes.conflictInvoiceBalanceInvalid,
    );
    expect(
      crossCurrency.failureOrNull?.code,
      PaymentFailureCodes.conflictInvoiceBalanceInvalid,
    );
  });
}

Invoice _invoice({required InvoiceStatus status}) {
  final currency = CurrencyCode.tryParse('AED')!;
  final zero = Money(minorUnits: 0, currency: currency);
  final total = Money(minorUnits: 120000, currency: currency);
  return Invoice(
    id: 'invoice-1',
    companyId: 'company-1',
    customer: const InvoiceCustomerSnapshot(
      companyId: 'company-1',
      customerId: 'customer-1',
      name: 'Customer',
    ),
    status: status,
    currency: currency,
    lines: [InvoiceTripLine(tripId: 'trip-1', amount: total)],
    totals: InvoiceTotals(
      subtotal: total,
      discount: zero,
      taxableAmount: total,
      taxRate: TaxRate.tryCreate(0)!,
      taxAmount: zero,
      grandTotal: total,
    ),
    createdAt: DateTime.utc(2026, 8, 10),
    updatedAt: DateTime.utc(2026, 8, 10),
  );
}

Payment _payment({
  String invoiceId = 'invoice-1',
  int amountMinorUnits = 40000,
  CurrencyCode? currency,
}) {
  final paymentCurrency = currency ?? CurrencyCode.tryParse('AED')!;
  return Payment(
    id: 'payment-1',
    companyId: 'company-1',
    invoiceId: invoiceId,
    customerId: 'customer-1',
    paymentMethodId: 'method-1',
    paymentDate: DateTime.utc(2026, 8, 10),
    amount: Money(
      minorUnits: amountMinorUnits,
      currency: paymentCurrency,
    ),
    createdAt: DateTime.utc(2026, 8, 10),
  );
}
