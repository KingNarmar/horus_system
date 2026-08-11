import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
import 'package:horus_system/features/invoices/domain/value_objects/invoice_number.dart';
import 'package:horus_system/features/invoices/domain/value_objects/tax_rate.dart';
import 'package:horus_system/features/payment_methods/domain/entities/payment_method.dart';
import 'package:horus_system/features/payments/domain/entities/payment.dart';
import 'package:horus_system/features/payments/presentation/cubit/payments_state.dart';
import 'package:horus_system/features/payments/presentation/widgets/payments_list.dart';

void main() {
  testWidgets('mobile payment card renders company-scoped payment context', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            child: PaymentsList(state: _state(), fractionDigits: 2),
          ),
        ),
      ),
    );

    expect(find.text('INV-2026-000001'), findsOneWidget);
    expect(find.text('Acme Transport'), findsOneWidget);
    expect(find.text('Cash'), findsOneWidget);
    expect(find.text('AED 400.00'), findsOneWidget);
    expect(find.text('REF-1'), findsOneWidget);
  });
}

PaymentsLoaded _state() {
  final invoice = _invoice();
  final currency = CurrencyCode.tryParse('AED')!;
  return PaymentsLoaded(
    currentCompanyContext: CurrentCompanyContext(
      company: const Company(
        id: 'company-1',
        name: 'Company',
        baseCurrencyCode: 'AED',
        baseCurrencyFractionDigits: 2,
      ),
      role: CompanyRole.accountant,
    ),
    allPayments: [
      Payment(
        id: 'payment-1',
        companyId: 'company-1',
        invoiceId: invoice.id,
        customerId: 'customer-1',
        paymentMethodId: 'method-1',
        paymentDate: DateTime(2026, 8, 10),
        amount: Money(minorUnits: 40000, currency: currency),
        referenceNumber: 'REF-1',
        createdAt: DateTime.utc(2026, 8, 10),
      ),
    ],
    invoices: [invoice],
    paymentMethods: const [
      PaymentMethod(
        id: 'method-1',
        companyId: 'company-1',
        name: 'Cash',
        isActive: true,
      ),
    ],
    canRegisterPayments: true,
  );
}

Invoice _invoice() {
  final currency = CurrencyCode.tryParse('AED')!;
  final zero = Money(minorUnits: 0, currency: currency);
  final total = Money(minorUnits: 120000, currency: currency);
  return Invoice(
    id: 'invoice-1',
    companyId: 'company-1',
    customer: const InvoiceCustomerSnapshot(
      companyId: 'company-1',
      customerId: 'customer-1',
      name: 'Acme Transport',
    ),
    status: InvoiceStatus.partiallyPaid,
    number: InvoiceNumber.tryParse('INV-2026-000001'),
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
