import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/core/domain/value_objects/currency_code.dart';
import 'package:horus_system/core/domain/value_objects/money.dart';
import 'package:horus_system/features/customer_statements/domain/entities/customer_statement.dart';
import 'package:horus_system/features/customer_statements/domain/entities/customer_statement_line.dart';
import 'package:horus_system/features/customer_statements/domain/entities/customer_statement_movement.dart';
import 'package:horus_system/features/customer_statements/domain/entities/customer_statement_movement_type.dart';
import 'package:horus_system/features/customer_statements/presentation/widgets/customer_statement_movements.dart';

void main() {
  testWidgets('mobile cards render invoice and signed payment balances', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            child: CustomerStatementMovements(statement: _statement()),
          ),
        ),
      ),
    );

    expect(find.text('INV-1'), findsOneWidget);
    expect(find.text('REF-1'), findsOneWidget);
    expect(find.text('AED 1,200.00'), findsNWidgets(2));
    expect(find.text('AED -400.00'), findsOneWidget);
    expect(find.text('AED 800.00'), findsOneWidget);
  });
}

CustomerStatement _statement() {
  final currency = CurrencyCode.tryParse('AED')!;
  final invoiceAmount = Money(minorUnits: 120000, currency: currency);
  final paymentAmount = Money(minorUnits: 40000, currency: currency);

  return CustomerStatement(
    companyId: 'company-1',
    customerId: 'customer-1',
    customerName: 'Customer',
    customerIsActive: true,
    currency: currency,
    fractionDigits: 2,
    businessTimezone: 'Asia/Dubai',
    fromDate: null,
    toDate: null,
    openingBalance: Money(minorUnits: 0, currency: currency),
    totalInvoiced: invoiceAmount,
    totalPaid: paymentAmount,
    closingBalance: Money(minorUnits: 80000, currency: currency),
    lines: [
      CustomerStatementLine(
        movement: CustomerStatementMovement(
          type: CustomerStatementMovementType.invoice,
          sourceId: 'invoice-1',
          businessDate: DateTime(2026, 8, 10),
          eventTimestamp: DateTime.utc(2026, 8, 10, 18, 31),
          amount: invoiceAmount,
          reference: 'INV-1',
          relatedInvoiceId: 'invoice-1',
        ),
        signedAmount: invoiceAmount,
        runningBalance: invoiceAmount,
      ),
      CustomerStatementLine(
        movement: CustomerStatementMovement(
          type: CustomerStatementMovementType.payment,
          sourceId: 'payment-1',
          businessDate: DateTime(2026, 8, 10),
          eventTimestamp: DateTime.utc(2026, 8, 10, 18, 35),
          amount: paymentAmount,
          reference: 'REF-1',
          relatedInvoiceId: 'invoice-1',
        ),
        signedAmount: Money(minorUnits: -40000, currency: currency),
        runningBalance: Money(minorUnits: 80000, currency: currency),
      ),
    ],
  );
}
