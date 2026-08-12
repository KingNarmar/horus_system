import 'package:horus_system/core/domain/value_objects/currency_code.dart';
import 'package:horus_system/core/domain/value_objects/money.dart';
import 'package:horus_system/features/customer_statements/domain/entities/customer_statement_movement.dart';
import 'package:horus_system/features/customer_statements/domain/entities/customer_statement_movement_type.dart';
import 'package:horus_system/features/customer_statements/domain/entities/customer_statement_source.dart';
import 'package:horus_system/features/customer_statements/domain/failures/customer_statement_failure_codes.dart';
import 'package:horus_system/features/customer_statements/domain/services/customer_statement_calculator.dart';
import 'package:test/test.dart';

void main() {
  const calculator = CustomerStatementCalculator();
  final aed = CurrencyCode.tryParse('AED')!;

  test('returns zero balances for an empty all-time statement', () {
    final result = calculator.calculate(
      source: _source(currency: aed),
      expectedCompanyId: 'company-1',
      expectedCustomerId: 'customer-1',
      expectedCurrency: aed,
      expectedFractionDigits: 2,
      expectedBusinessTimezone: 'Asia/Dubai',
    );

    expect(result.failureOrNull, isNull);
    expect(result.dataOrNull!.openingBalance.minorUnits, 0);
    expect(result.dataOrNull!.closingBalance.minorUnits, 0);
    expect(result.dataOrNull!.lines, isEmpty);
  });

  test('calculates invoice and payment running balances from minor units', () {
    final result = calculator.calculate(
      source: _source(
        currency: aed,
        movements: [
          _movement(
            type: CustomerStatementMovementType.payment,
            id: 'payment-2',
            amount: 80000,
            eventTimestamp: DateTime.utc(2026, 8, 10, 18, 37),
            currency: aed,
          ),
          _movement(
            type: CustomerStatementMovementType.invoice,
            id: 'invoice-1',
            amount: 120000,
            eventTimestamp: DateTime.utc(2026, 8, 10, 18, 31),
            currency: aed,
          ),
          _movement(
            type: CustomerStatementMovementType.payment,
            id: 'payment-1',
            amount: 40000,
            eventTimestamp: DateTime.utc(2026, 8, 10, 18, 35),
            currency: aed,
          ),
        ],
      ),
      expectedCompanyId: 'company-1',
      expectedCustomerId: 'customer-1',
      expectedCurrency: aed,
      expectedFractionDigits: 2,
      expectedBusinessTimezone: 'Asia/Dubai',
    );

    expect(result.failureOrNull, isNull);
    final statement = result.dataOrNull!;
    expect(statement.openingBalance.minorUnits, 0);
    expect(statement.totalInvoiced.minorUnits, 120000);
    expect(statement.totalPaid.minorUnits, 120000);
    expect(statement.closingBalance.minorUnits, 0);
    expect(statement.lines.map((line) => line.runningBalance.minorUnits), [
      120000,
      80000,
      0,
    ]);
    expect(statement.lines[1].signedAmount.minorUnits, -40000);
  });

  test('orders invoice before payment when timestamps are identical', () {
    final timestamp = DateTime.utc(2026, 8, 10, 18, 31);
    final result = calculator.calculate(
      source: _source(
        currency: aed,
        movements: [
          _movement(
            type: CustomerStatementMovementType.payment,
            id: 'payment-1',
            amount: 40000,
            eventTimestamp: timestamp,
            currency: aed,
          ),
          _movement(
            type: CustomerStatementMovementType.invoice,
            id: 'invoice-1',
            amount: 120000,
            eventTimestamp: timestamp,
            currency: aed,
          ),
        ],
      ),
      expectedCompanyId: 'company-1',
      expectedCustomerId: 'customer-1',
      expectedCurrency: aed,
      expectedFractionDigits: 2,
      expectedBusinessTimezone: 'Asia/Dubai',
    );

    expect(result.failureOrNull, isNull);
    expect(
      result.dataOrNull!.lines.first.movement.type,
      CustomerStatementMovementType.invoice,
    );
  });

  test('calculates opening balance strictly before from date', () {
    final result = calculator.calculate(
      source: _source(
        currency: aed,
        fromDate: DateTime(2026, 8, 11),
        openingInvoices: [Money(minorUnits: 120000, currency: aed)],
        openingPayments: [Money(minorUnits: 40000, currency: aed)],
      ),
      expectedCompanyId: 'company-1',
      expectedCustomerId: 'customer-1',
      expectedCurrency: aed,
      expectedFractionDigits: 2,
      expectedBusinessTimezone: 'Asia/Dubai',
      expectedFromDate: DateTime(2026, 8, 11),
    );

    expect(result.failureOrNull, isNull);
    expect(result.dataOrNull!.openingBalance.minorUnits, 80000);
    expect(result.dataOrNull!.closingBalance.minorUnits, 80000);
  });

  test('rejects opening aggregates when no from date exists', () {
    final result = calculator.calculate(
      source: _source(
        currency: aed,
        openingInvoices: [Money(minorUnits: 120000, currency: aed)],
      ),
      expectedCompanyId: 'company-1',
      expectedCustomerId: 'customer-1',
      expectedCurrency: aed,
      expectedFractionDigits: 2,
      expectedBusinessTimezone: 'Asia/Dubai',
    );

    expect(
      result.failureOrNull?.code,
      CustomerStatementFailureCodes.conflictSourceInvalid,
    );
  });

  test('rejects source company or customer mismatch', () {
    final result = calculator.calculate(
      source: _source(currency: aed, companyId: 'other-company'),
      expectedCompanyId: 'company-1',
      expectedCustomerId: 'customer-1',
      expectedCurrency: aed,
      expectedFractionDigits: 2,
      expectedBusinessTimezone: 'Asia/Dubai',
    );

    expect(
      result.failureOrNull?.code,
      CustomerStatementFailureCodes.conflictSourceInvalid,
    );
  });

  test('rejects requested period mismatch from persisted source', () {
    final result = calculator.calculate(
      source: _source(currency: aed, fromDate: DateTime(2026, 8, 9)),
      expectedCompanyId: 'company-1',
      expectedCustomerId: 'customer-1',
      expectedCurrency: aed,
      expectedFractionDigits: 2,
      expectedBusinessTimezone: 'Asia/Dubai',
      expectedFromDate: DateTime(2026, 8, 10),
    );

    expect(
      result.failureOrNull?.code,
      CustomerStatementFailureCodes.conflictSourceInvalid,
    );
  });

  test('rejects source currency mismatch', () {
    final usd = CurrencyCode.tryParse('USD')!;
    final result = calculator.calculate(
      source: _source(currency: usd),
      expectedCompanyId: 'company-1',
      expectedCustomerId: 'customer-1',
      expectedCurrency: aed,
      expectedFractionDigits: 2,
      expectedBusinessTimezone: 'Asia/Dubai',
    );

    expect(
      result.failureOrNull?.code,
      CustomerStatementFailureCodes.conflictCurrencyMismatch,
    );
  });

  test('rejects movement currency mismatch with typed currency failure', () {
    final usd = CurrencyCode.tryParse('USD')!;
    final result = calculator.calculate(
      source: _source(
        currency: aed,
        movements: [
          _movement(
            type: CustomerStatementMovementType.payment,
            id: 'payment-1',
            amount: 40000,
            eventTimestamp: DateTime.utc(2026, 8, 10),
            currency: usd,
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
      CustomerStatementFailureCodes.conflictCurrencyMismatch,
    );
  });

  test('rejects duplicate financial movements', () {
    final duplicated = _movement(
      type: CustomerStatementMovementType.invoice,
      id: 'invoice-1',
      amount: 120000,
      eventTimestamp: DateTime.utc(2026, 8, 10),
      currency: aed,
    );
    final result = calculator.calculate(
      source: _source(currency: aed, movements: [duplicated, duplicated]),
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

  test('rejects non-positive movement amount', () {
    final result = calculator.calculate(
      source: _source(
        currency: aed,
        movements: [
          _movement(
            type: CustomerStatementMovementType.payment,
            id: 'payment-1',
            amount: 0,
            eventTimestamp: DateTime.utc(2026, 8, 10),
            currency: aed,
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

  test('rejects movement outside requested period', () {
    final result = calculator.calculate(
      source: _source(
        currency: aed,
        fromDate: DateTime(2026, 8, 10),
        toDate: DateTime(2026, 8, 10),
        movements: [
          _movement(
            type: CustomerStatementMovementType.invoice,
            id: 'invoice-1',
            amount: 120000,
            businessDate: DateTime(2026, 8, 11),
            eventTimestamp: DateTime.utc(2026, 8, 11),
            currency: aed,
          ),
        ],
      ),
      expectedCompanyId: 'company-1',
      expectedCustomerId: 'customer-1',
      expectedCurrency: aed,
      expectedFractionDigits: 2,
      expectedBusinessTimezone: 'Asia/Dubai',
      expectedFromDate: DateTime(2026, 8, 10),
      expectedToDate: DateTime(2026, 8, 10),
    );

    expect(
      result.failureOrNull?.code,
      CustomerStatementFailureCodes.conflictMovementInvalid,
    );
  });
}

CustomerStatementSource _source({
  required CurrencyCode currency,
  String companyId = 'company-1',
  String customerId = 'customer-1',
  DateTime? fromDate,
  DateTime? toDate,
  List<Money> openingInvoices = const [],
  List<Money> openingPayments = const [],
  List<CustomerStatementMovement> movements = const [],
}) {
  return CustomerStatementSource(
    companyId: companyId,
    customerId: customerId,
    customerName: 'Customer',
    customerIsActive: true,
    baseCurrency: currency,
    baseCurrencyFractionDigits: 2,
    businessTimezone: 'Asia/Dubai',
    fromDate: fromDate,
    toDate: toDate,
    openingInvoiceAmounts: openingInvoices,
    openingPaymentAmounts: openingPayments,
    movements: movements,
  );
}

CustomerStatementMovement _movement({
  required CustomerStatementMovementType type,
  required String id,
  required int amount,
  required DateTime eventTimestamp,
  required CurrencyCode currency,
  DateTime? businessDate,
}) {
  return CustomerStatementMovement(
    type: type,
    sourceId: id,
    businessDate: businessDate ?? DateTime(2026, 8, 10),
    eventTimestamp: eventTimestamp,
    amount: Money(minorUnits: amount, currency: currency),
    reference: type == CustomerStatementMovementType.invoice ? 'INV-1' : 'REF',
    relatedInvoiceId: 'invoice-1',
  );
}
