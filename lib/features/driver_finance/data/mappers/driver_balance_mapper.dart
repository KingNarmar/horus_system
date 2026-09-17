import '../../../../core/data/utils/db_date.dart';
import '../../../../core/data/utils/db_timestamp.dart';
import '../../../../core/domain/value_objects/currency_code.dart';
import '../../../../core/domain/value_objects/currency_configuration.dart';
import '../../../../core/domain/value_objects/money.dart';
import '../../domain/entities/driver_balance.dart';
import '../../domain/entities/driver_balance_checkpoint.dart';
import '../constants/driver_finance_db_fields.dart';
import '../models/driver_balance_model.dart';

class DriverBalanceSourceMapper {
  const DriverBalanceSourceMapper();

  DriverBalanceModel map({
    required String companyId,
    required String driverId,
    required CurrencyConfiguration configuration,
    required Map<String, dynamic>? checkpointRow,
    required List<Map<String, dynamic>> movementRows,
    required List<Map<String, dynamic>> tripExpenseRows,
  }) {
    var totalAdvancesMinorUnits = 0;
    var totalDriverChargesMinorUnits = 0;
    var totalCashReturnsMinorUnits = 0;

    for (final row in movementRows) {
      _validateCurrency(row, configuration);
      final amountMinorUnits = _positiveInt(
        row[DriverFinanceDbFields.amountMinorUnits],
      );
      switch (row[DriverFinanceDbFields.movementType]?.toString()) {
        case DriverFinanceDbValues.movementAdvance:
          totalAdvancesMinorUnits += amountMinorUnits;
          break;
        case DriverFinanceDbValues.movementDriverCharge:
          totalDriverChargesMinorUnits += amountMinorUnits;
          break;
        case DriverFinanceDbValues.movementCashReturn:
          totalCashReturnsMinorUnits += amountMinorUnits;
          break;
        default:
          throw FormatException(
            'Unsupported driver financial movement type: '
            '${row[DriverFinanceDbFields.movementType]}',
          );
      }
    }

    var totalTripExpenseCreditsMinorUnits = 0;
    for (final row in tripExpenseRows) {
      final fundingSource = row[DriverFinanceDbFields.fundingSource]?.toString();
      if (fundingSource != DriverFinanceDbValues.fundingSourceDriverAdvance &&
          fundingSource != DriverFinanceDbValues.fundingSourceDriverCash) {
        throw FormatException(
          'Unsupported driver-paid trip expense source: $fundingSource',
        );
      }
      _validateCurrency(row, configuration);
      totalTripExpenseCreditsMinorUnits += _positiveInt(
        row[DriverFinanceDbFields.amountMinorUnits],
      );
    }

    if (checkpointRow != null) {
      _validateCurrency(checkpointRow, configuration);
    }

    return DriverBalanceModel(
      companyId: companyId,
      driverId: driverId,
      currencyCode: configuration.currency.value,
      currencyFractionDigits: configuration.fractionDigits,
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
          : _int(
              checkpointRow[
                  DriverFinanceDbFields.checkpointClosingBalanceMinorUnits],
            ),
      totalAdvancesMinorUnits: totalAdvancesMinorUnits,
      totalDriverChargesMinorUnits: totalDriverChargesMinorUnits,
      totalTripExpenseCreditsMinorUnits: totalTripExpenseCreditsMinorUnits,
      totalCashReturnsMinorUnits: totalCashReturnsMinorUnits,
    );
  }

  void _validateCurrency(
    Map<String, dynamic> row,
    CurrencyConfiguration configuration,
  ) {
    final currencyCode = row[DriverFinanceDbFields.currencyCode]?.toString();
    final fractionDigits = _int(
      row[DriverFinanceDbFields.currencyFractionDigits],
    );
    if (currencyCode != configuration.currency.value ||
        fractionDigits != configuration.fractionDigits) {
      throw const FormatException('Driver finance currency mismatch.');
    }
  }

  int _positiveInt(Object? value) {
    final amount = _int(value);
    if (amount <= 0) {
      throw FormatException('Invalid positive minor-unit amount: $value');
    }
    return amount;
  }

  int _int(Object? value) {
    if (value is int) return value;
    if (value is num && value == value.toInt()) return value.toInt();
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

extension DriverBalanceModelMapper on DriverBalanceModel {
  DriverBalance toEntity() {
    final currency = CurrencyCode.tryParse(currencyCode);
    if (currency == null) {
      throw FormatException('Invalid driver balance currency: $currencyCode');
    }

    Money money(int minorUnits) => Money(
      minorUnits: minorUnits,
      currency: currency,
    );

    final checkpoint = hasCheckpoint
        ? DriverBalanceCheckpoint(
            settlementId: checkpointSettlementId!,
            periodEnd: checkpointPeriodEnd!,
            snapshotCreatedAt: checkpointSnapshotCreatedAt!,
            closingBalance: money(checkpointClosingBalanceMinorUnits),
          )
        : null;

    return DriverBalance(
      companyId: companyId,
      driverId: driverId,
      checkpoint: checkpoint,
      totalAdvances: money(totalAdvancesMinorUnits),
      totalDriverCharges: money(totalDriverChargesMinorUnits),
      totalTripExpenseCredits: money(totalTripExpenseCreditsMinorUnits),
      totalCashReturns: money(totalCashReturnsMinorUnits),
    );
  }
}
