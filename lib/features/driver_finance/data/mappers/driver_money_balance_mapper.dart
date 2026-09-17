import '../../../../core/data/utils/db_date.dart';
import '../../../../core/data/utils/db_timestamp.dart';
import '../../../../core/domain/value_objects/currency_code.dart';
import '../../../../core/domain/value_objects/money.dart';
import '../../domain/entities/driver_money_balance.dart';
import '../../domain/entities/driver_money_balance_checkpoint.dart';
import '../constants/driver_finance_db_fields.dart';
import '../models/driver_money_balance_model.dart';

final class DriverMoneyBalanceSourceMapper {
  const DriverMoneyBalanceSourceMapper();

  DriverMoneyBalanceModel map({
    required String companyId,
    required String driverId,
    required String currencyCode,
    required int currencyFractionDigits,
    required Map<String, dynamic>? checkpointRow,
    required List<Map<String, dynamic>> movementRows,
    required List<Map<String, dynamic>> expenseLedgerRows,
  }) {
    _validateCurrencySnapshot(currencyCode, currencyFractionDigits);

    var totalAdvancesMinorUnits = 0;
    var totalDriverChargesMinorUnits = 0;
    var totalCashReturnsMinorUnits = 0;

    for (final row in movementRows) {
      _validateRowCurrency(row, currencyCode, currencyFractionDigits);
      final amount = _positiveMinorUnits(
        row[DriverFinanceDbFields.amountMinorUnits],
      );
      switch (row[DriverFinanceDbFields.movementType]?.toString()) {
        case DriverFinanceDbValues.movementAdvance:
          totalAdvancesMinorUnits += amount;
          break;
        case DriverFinanceDbValues.movementDriverCharge:
          totalDriverChargesMinorUnits += amount;
          break;
        case DriverFinanceDbValues.movementCashReturn:
          totalCashReturnsMinorUnits += amount;
          break;
        default:
          throw FormatException(
            'Unsupported driver financial movement type: '
            '${row[DriverFinanceDbFields.movementType]}',
          );
      }
    }

    var totalTripExpenseCreditsMinorUnits = 0;
    for (final row in expenseLedgerRows) {
      _validateRowCurrency(row, currencyCode, currencyFractionDigits);
      final fundingSource = row[DriverFinanceDbFields.fundingSource]
          ?.toString();
      if (fundingSource != DriverFinanceDbValues.paidByDriverAdvance &&
          fundingSource != DriverFinanceDbValues.paidByDriverCash) {
        throw FormatException(
          'Unsupported driver-paid expense funding source: $fundingSource',
        );
      }
      totalTripExpenseCreditsMinorUnits += _positiveMinorUnits(
        row[DriverFinanceDbFields.amountMinorUnits],
      );
    }

    if (checkpointRow != null) {
      _validateRowCurrency(checkpointRow, currencyCode, currencyFractionDigits);
    }

    return DriverMoneyBalanceModel(
      companyId: companyId,
      driverId: driverId,
      currencyCode: currencyCode,
      currencyFractionDigits: currencyFractionDigits,
      checkpointSettlementId: checkpointRow == null
          ? null
          : _requiredText(
              checkpointRow[DriverFinanceDbFields.checkpointSettlementId],
            ),
      checkpointPeriodEnd: checkpointRow == null
          ? null
          : DbDate.decode(
              checkpointRow[DriverFinanceDbFields.checkpointPeriodEnd],
              field: DriverFinanceDbFields.checkpointPeriodEnd,
            ),
      checkpointSnapshotCreatedAt: checkpointRow == null
          ? null
          : DbTimestamp.decode(
              checkpointRow[DriverFinanceDbFields.checkpointSnapshotCreatedAt],
              field: DriverFinanceDbFields.checkpointSnapshotCreatedAt,
            ),
      checkpointClosingBalanceMinorUnits: checkpointRow == null
          ? 0
          : _minorUnits(
              checkpointRow[DriverFinanceDbFields
                  .checkpointClosingBalanceMinorUnits],
            ),
      totalAdvancesMinorUnits: totalAdvancesMinorUnits,
      totalDriverChargesMinorUnits: totalDriverChargesMinorUnits,
      totalTripExpenseCreditsMinorUnits: totalTripExpenseCreditsMinorUnits,
      totalCashReturnsMinorUnits: totalCashReturnsMinorUnits,
    );
  }

  void _validateCurrencySnapshot(String currencyCode, int fractionDigits) {
    if (CurrencyCode.tryParse(currencyCode) == null) {
      throw FormatException('Invalid currency code: $currencyCode');
    }
    if (fractionDigits < 0 || fractionDigits > 4) {
      throw FormatException(
        'Invalid currency fraction digits: $fractionDigits',
      );
    }
  }

  void _validateRowCurrency(
    Map<String, dynamic> row,
    String expectedCurrencyCode,
    int expectedFractionDigits,
  ) {
    final rowCurrencyCode = row[DriverFinanceDbFields.currencyCode]?.toString();
    final rowFractionDigits = _intValue(
      row[DriverFinanceDbFields.currencyFractionDigits],
    );
    if (rowCurrencyCode != expectedCurrencyCode ||
        rowFractionDigits != expectedFractionDigits) {
      throw const FormatException('Driver balance currency snapshot mismatch.');
    }
  }

  int _positiveMinorUnits(Object? value) {
    final amount = _minorUnits(value);
    if (amount <= 0) {
      throw FormatException('Invalid positive minor-unit amount: $value');
    }
    return amount;
  }

  int _minorUnits(Object? value) => _intValue(value);

  int _intValue(Object? value) {
    if (value is int) return value;
    final parsed = int.tryParse(value?.toString() ?? '');
    if (parsed == null) {
      throw FormatException('Invalid integer value: $value');
    }
    return parsed;
  }

  String _requiredText(Object? value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) {
      throw const FormatException('Checkpoint settlement id is required.');
    }
    return text;
  }
}

extension DriverMoneyBalanceModelMapper on DriverMoneyBalanceModel {
  DriverMoneyBalance toEntity() {
    final currency = CurrencyCode.tryParse(currencyCode);
    if (currency == null) {
      throw FormatException('Invalid currency code: $currencyCode');
    }

    final checkpoint = hasCheckpoint
        ? DriverMoneyBalanceCheckpoint(
            settlementId: checkpointSettlementId!,
            periodEnd: checkpointPeriodEnd!,
            snapshotCreatedAt: checkpointSnapshotCreatedAt!,
            closingBalance: Money(
              minorUnits: checkpointClosingBalanceMinorUnits,
              currency: currency,
            ),
            currencyFractionDigits: currencyFractionDigits,
          )
        : null;

    return DriverMoneyBalance(
      companyId: companyId,
      driverId: driverId,
      currency: currency,
      currencyFractionDigits: currencyFractionDigits,
      checkpoint: checkpoint,
      totalAdvances: Money(
        minorUnits: totalAdvancesMinorUnits,
        currency: currency,
      ),
      totalDriverCharges: Money(
        minorUnits: totalDriverChargesMinorUnits,
        currency: currency,
      ),
      totalTripExpenseCredits: Money(
        minorUnits: totalTripExpenseCreditsMinorUnits,
        currency: currency,
      ),
      totalCashReturns: Money(
        minorUnits: totalCashReturnsMinorUnits,
        currency: currency,
      ),
    );
  }
}
