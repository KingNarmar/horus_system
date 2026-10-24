import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/core/domain/value_objects/business_date.dart';
import 'package:horus_system/core/domain/value_objects/currency_code.dart';
import 'package:horus_system/core/domain/value_objects/money.dart';
import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/entities/current_company_context.dart';
import 'package:horus_system/features/invoices/domain/entities/invoice.dart';
import 'package:horus_system/features/invoices/domain/entities/invoice_customer_snapshot.dart';
import 'package:horus_system/features/invoices/domain/entities/invoice_status.dart';
import 'package:horus_system/features/invoices/domain/entities/invoice_totals.dart';
import 'package:horus_system/features/invoices/domain/entities/invoice_trip_line.dart';
import 'package:horus_system/features/invoices/domain/value_objects/invoice_date.dart';
import 'package:horus_system/features/invoices/domain/value_objects/tax_rate.dart';
import 'package:horus_system/features/payment_methods/domain/entities/payment_method.dart';
import 'package:horus_system/features/payments/domain/entities/payable_invoice.dart';
import 'package:horus_system/features/payments/domain/entities/payment_balance.dart';
import 'package:horus_system/features/payments/presentation/cubit/register_payment_state.dart';
import 'package:horus_system/features/payments/presentation/widgets/register_payment_form.dart';

void main() {
  testWidgets('invalidation drops stale invoice choice, keeps entered fields', (
    tester,
  ) async {
    await tester.pumpWidget(_app([_payable('invoice-1')]));

    await tester.enterText(find.byType(TextFormField).at(0), '50.00');
    await tester.enterText(find.byType(TextFormField).at(1), 'REF-42');
    await tester.enterText(find.byType(TextFormField).at(2), 'Test note');

    // The selected invoice was cancelled on another device; an alternative
    // remains payable. Do not auto-select that alternative for this payment.
    await tester.pumpWidget(_app([_payable('invoice-2')]));
    await tester.pump();

    expect(find.text('50.00'), findsOneWidget);
    expect(find.text('REF-42'), findsOneWidget);
    expect(find.text('Test note'), findsOneWidget);
    expect(
      find.text(
        'The selected invoice is no longer payable. Select another invoice.',
      ),
      findsOneWidget,
    );
    expect(find.text('Select an invoice'), findsOneWidget);

    // Form validation, not an implicit switch, blocks a stale payment.
    await tester.tap(find.text('Register payment').last);
    await tester.pump();
    expect(find.text('Select an invoice.'), findsOneWidget);
  });
}

Widget _app(List<PayableInvoice> invoices) {
  return MaterialApp(
    home: Scaffold(
      body: RegisterPaymentForm(
        state: RegisterPaymentReady(
          currentCompanyContext: CurrentCompanyContext(
            company: const Company(
              id: 'company-1',
              name: 'Company',
              baseCurrencyCode: 'AED',
              baseCurrencyFractionDigits: 2,
              businessTimezone: 'Asia/Dubai',
            ),
            role: CompanyRole.accountant,
          ),
          payableInvoices: invoices,
          paymentMethods: const [
            PaymentMethod(
              id: 'method-1',
              companyId: 'company-1',
              name: 'Cash',
              isActive: true,
            ),
          ],
          businessDate: BusinessDate(year: 2026, month: 8, day: 10),
        ),
      ),
    ),
  );
}

PayableInvoice _payable(String id) {
  final currency = CurrencyCode.tryParse('AED')!;
  final zero = Money(minorUnits: 0, currency: currency);
  final total = Money(minorUnits: 10000, currency: currency);
  return PayableInvoice(
    invoice: Invoice(
      id: id,
      companyId: 'company-1',
      customer: const InvoiceCustomerSnapshot(
        companyId: 'company-1',
        customerId: 'customer-1',
        name: 'Customer',
      ),
      status: InvoiceStatus.issued,
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
      issueDate: InvoiceDate.fromBusinessDate(
        BusinessDate(year: 2026, month: 8, day: 10),
      ),
      createdAt: DateTime.utc(2026, 8, 10),
      updatedAt: DateTime.utc(2026, 8, 10),
    ),
    balance: PaymentBalance(total: total, paid: zero, remaining: total),
  );
}
