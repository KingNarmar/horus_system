import '../../../../core/domain/value_objects/currency_code.dart';
import '../../../../core/domain/value_objects/money.dart';
import '../../../../core/errors/common_failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/customer_statement.dart';
import '../entities/customer_statement_line.dart';
import '../entities/customer_statement_movement.dart';
import '../entities/customer_statement_movement_type.dart';
import '../entities/customer_statement_source.dart';
import '../failures/customer_statement_failure_codes.dart';

final class CustomerStatementCalculator {
  const CustomerStatementCalculator();

  Result<CustomerStatement> calculate({
    required CustomerStatementSource source,
    required String expectedCompanyId,
    required String expectedCustomerId,
    required CurrencyCode expectedCurrency,
    required int expectedFractionDigits,
    required String expectedBusinessTimezone,
    DateTime? expectedFromDate,
    DateTime? expectedToDate,
  }) {
    if (!_scopeMatches(
      source: source,
      expectedCompanyId: expectedCompanyId,
      expectedCustomerId: expectedCustomerId,
      expectedFractionDigits: expectedFractionDigits,
      expectedBusinessTimezone: expectedBusinessTimezone,
      expectedFromDate: expectedFromDate,
      expectedToDate: expectedToDate,
    )) {
      return const FailureResult(
        ConflictFailure(
          code: CustomerStatementFailureCodes.conflictSourceInvalid,
        ),
      );
    }

    if (source.baseCurrency != expectedCurrency) {
      return const FailureResult(
        ConflictFailure(
          code: CustomerStatementFailureCodes.conflictCurrencyMismatch,
        ),
      );
    }

    if (expectedFromDate == null &&
        (source.openingInvoiceAmounts.isNotEmpty ||
            source.openingPaymentAmounts.isNotEmpty)) {
      return const FailureResult(
        ConflictFailure(
          code: CustomerStatementFailureCodes.conflictSourceInvalid,
        ),
      );
    }

    final openingAmounts = [
      ...source.openingInvoiceAmounts,
      ...source.openingPaymentAmounts,
    ];
    if (openingAmounts.any((amount) => amount.currency != expectedCurrency)) {
      return _currencyFailure();
    }
    if (openingAmounts.any((amount) => amount.minorUnits < 0)) {
      return const FailureResult(
        ConflictFailure(
          code: CustomerStatementFailureCodes.conflictSourceInvalid,
        ),
      );
    }

    final openingInvoices = Money(
      minorUnits: _sumMinorUnits(source.openingInvoiceAmounts),
      currency: expectedCurrency,
    );
    final openingPayments = Money(
      minorUnits: _sumMinorUnits(source.openingPaymentAmounts),
      currency: expectedCurrency,
    );
    final openingBalance = openingInvoices.subtract(openingPayments);
    final movements = List<CustomerStatementMovement>.of(source.movements)
      ..sort(_compareMovements);

    final seenMovements = <String>{};
    var invoicedMinorUnits = 0;
    var paidMinorUnits = 0;
    var runningBalance = openingBalance;
    final lines = <CustomerStatementLine>[];

    for (final movement in movements) {
      if (movement.amount.currency != expectedCurrency) {
        return _currencyFailure();
      }

      if (!_isValidMovement(
        movement,
        fromDate: expectedFromDate,
        toDate: expectedToDate,
      )) {
        return const FailureResult(
          ConflictFailure(
            code: CustomerStatementFailureCodes.conflictMovementInvalid,
          ),
        );
      }

      final identity = '${movement.type.name}:${movement.sourceId}';
      if (!seenMovements.add(identity)) {
        return const FailureResult(
          ConflictFailure(
            code: CustomerStatementFailureCodes.conflictMovementInvalid,
          ),
        );
      }

      final signedAmount = switch (movement.type) {
        CustomerStatementMovementType.invoice => movement.amount,
        CustomerStatementMovementType.payment => Money(
          minorUnits: -movement.amount.minorUnits,
          currency: movement.amount.currency,
        ),
      };

      switch (movement.type) {
        case CustomerStatementMovementType.invoice:
          invoicedMinorUnits += movement.amount.minorUnits;
        case CustomerStatementMovementType.payment:
          paidMinorUnits += movement.amount.minorUnits;
      }

      runningBalance = runningBalance.add(signedAmount);
      lines.add(
        CustomerStatementLine(
          movement: movement,
          signedAmount: signedAmount,
          runningBalance: runningBalance,
        ),
      );
    }

    final totalInvoiced = Money(
      minorUnits: invoicedMinorUnits,
      currency: expectedCurrency,
    );
    final totalPaid = Money(
      minorUnits: paidMinorUnits,
      currency: expectedCurrency,
    );
    final closingBalance = openingBalance
        .add(totalInvoiced)
        .subtract(totalPaid);

    if (closingBalance != runningBalance) {
      return const FailureResult(
        ConflictFailure(
          code: CustomerStatementFailureCodes.conflictSourceInvalid,
        ),
      );
    }

    return Success(
      CustomerStatement(
        companyId: source.companyId,
        customerId: source.customerId,
        customerName: source.customerName,
        customerIsActive: source.customerIsActive,
        currency: expectedCurrency,
        fractionDigits: source.baseCurrencyFractionDigits,
        businessTimezone: source.businessTimezone,
        fromDate: source.fromDate,
        toDate: source.toDate,
        openingBalance: openingBalance,
        totalInvoiced: totalInvoiced,
        totalPaid: totalPaid,
        closingBalance: closingBalance,
        lines: List.unmodifiable(lines),
      ),
    );
  }

  Result<CustomerStatement> _currencyFailure() {
    return const FailureResult(
      ConflictFailure(
        code: CustomerStatementFailureCodes.conflictCurrencyMismatch,
      ),
    );
  }

  int _sumMinorUnits(Iterable<Money> amounts) {
    var minorUnits = 0;
    for (final amount in amounts) {
      minorUnits += amount.minorUnits;
    }
    return minorUnits;
  }

  bool _scopeMatches({
    required CustomerStatementSource source,
    required String expectedCompanyId,
    required String expectedCustomerId,
    required int expectedFractionDigits,
    required String expectedBusinessTimezone,
    required DateTime? expectedFromDate,
    required DateTime? expectedToDate,
  }) {
    return source.companyId == expectedCompanyId &&
        source.customerId == expectedCustomerId &&
        source.customerName.trim().isNotEmpty &&
        source.baseCurrencyFractionDigits == expectedFractionDigits &&
        source.businessTimezone == expectedBusinessTimezone &&
        _sameDate(source.fromDate, expectedFromDate) &&
        _sameDate(source.toDate, expectedToDate);
  }

  bool _isValidMovement(
    CustomerStatementMovement movement, {
    required DateTime? fromDate,
    required DateTime? toDate,
  }) {
    if (movement.sourceId.trim().isEmpty ||
        movement.relatedInvoiceId.trim().isEmpty ||
        !movement.amount.isPositive) {
      return false;
    }

    final businessDate = _dateOnly(movement.businessDate);
    if (fromDate != null && businessDate.isBefore(_dateOnly(fromDate))) {
      return false;
    }
    if (toDate != null && businessDate.isAfter(_dateOnly(toDate))) {
      return false;
    }
    return true;
  }

  int _compareMovements(
    CustomerStatementMovement left,
    CustomerStatementMovement right,
  ) {
    final dateComparison = _dateOnly(
      left.businessDate,
    ).compareTo(_dateOnly(right.businessDate));
    if (dateComparison != 0) return dateComparison;

    final timestampComparison = left.eventTimestamp.compareTo(
      right.eventTimestamp,
    );
    if (timestampComparison != 0) return timestampComparison;

    final typeComparison = left.type.index.compareTo(right.type.index);
    if (typeComparison != 0) return typeComparison;

    return left.sourceId.compareTo(right.sourceId);
  }

  bool _sameDate(DateTime? left, DateTime? right) {
    if (left == null || right == null) return left == right;
    return _dateOnly(left) == _dateOnly(right);
  }

  DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }
}
