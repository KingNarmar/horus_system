import 'package:horus_system/core/domain/value_objects/currency_code.dart';
import 'package:horus_system/core/domain/value_objects/money.dart';
import 'package:horus_system/features/customer_statements/domain/entities/customer_statement_movement.dart';
import 'package:horus_system/features/customer_statements/domain/entities/customer_statement_movement_type.dart';
import 'package:horus_system/features/customer_statements/domain/entities/customer_statement_source.dart';
import 'package:horus_system/features/customer_statements/domain/failures/customer_statement_failure_codes.dart';
import 'package:horus_system/features/customer_statements/domain/services/customer_statement_calculator.dart';
import 'package:test/test.dart';

void main() {
  test('rejects invoice movement with mismatched related invoice id', () {
    final aed = CurrencyCode.tryParse('AED')!;
    final result = const CustomerStatementCalculator().calculate(
      source: CustomerStatementSource(
        companyId: 'company-1',
        customerId: 'customer-1',
        customerName: 'Customer',
        customerIsActive: true,
        baseCurrency: aed,
        baseCurrencyFractionDigits: 2,
        businessTimezone: 'Asia/Dubai',
        fromDate: null,
        toDate: null,
        openingInvoiceAmounts: const [],
        openingPaymentAmounts: const [],
        movements: [
          CustomerStatementMovement(
            type: CustomerStatementMovementType.invoice,
            sourceId: 'invoice-1',
            businessDate: DateTime(2026, 8, 10),
            eventTimestamp: DateTime.utc(2026, 8, 10),
            amount: Money(minorUnits: 120000, currency: aed),
            reference: 'INV-1',
            relatedInvoiceId: 'invoice-2',
          ),
        ],
      ),
      expectedCompanyId: 'company-1',
      expectedCustomerId: 'customer-1',
      expectedCurrency: aed,
      expectedFractionDigits: 2,
      expectedBusinessTimezone: 'Asia/Dubai',
    );

    expect(
      result.failureOrNull?.code,
      CustomerStatementFailureCodes.conflictMovementInvalid,
    );
  });
}
