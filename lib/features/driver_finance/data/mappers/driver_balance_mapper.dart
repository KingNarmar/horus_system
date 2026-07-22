import '../../../../core/domain/services/driver_balance_calculator.dart';
import '../../domain/entities/driver_balance.dart';
import '../../domain/entities/driver_balance_checkpoint.dart';
import '../constants/driver_finance_db_fields.dart';
import '../models/driver_balance_model.dart';

class DriverBalanceSourceMapper {
  final DriverBalanceCalculator balanceCalculator;

  const DriverBalanceSourceMapper({
    this.balanceCalculator = const DriverBalanceCalculator(),
  });

  DriverBalanceModel map({
    required String companyId,
    required String driverId,
    required Map<String, dynamic>? checkpointRow,
    required List<Map<String, dynamic>> movementRows,
    required List<Map<String, dynamic>> tripExpenseRows,
  }) {
    var totalAdvances = 0.0;
    var totalDriverCharges = 0.0;
    var totalCashReturns = 0.0;

    for (final row in movementRows) {
      final amount = _positiveAmount(row[DriverFinanceDbFields.amount]);
      switch (row[DriverFinanceDbFields.movementType]?.toString()) {
        case DriverFinanceDbValues.movementAdvance:
          totalAdvances += amount;
          break;
        case DriverFinanceDbValues.movementDriverCharge:
          totalDriverCharges += amount;
          break;
        case DriverFinanceDbValues.movementCashReturn:
          totalCashReturns += amount;
          break;
        default:
          throw FormatException(
            'Unsupported driver financial movement type: '
            '${row[DriverFinanceDbFields.movementType]}',
          );
      }
    }

    var totalTripExpenseCredits = 0.0;
    for (final row in tripExpenseRows) {
      final paidBy = row[DriverFinanceDbFields.paidBy]?.toString();
      if (paidBy != DriverFinanceDbValues.paidByDriverAdvance &&
          paidBy != DriverFinanceDbValues.paidByDriverCash) {
        throw FormatException(
          'Unsupported driver-paid trip expense source: $paidBy',
        );
      }
      totalTripExpenseCredits += _positiveAmount(
        row[DriverFinanceDbFields.amount],
      );
    }

    return DriverBalanceModel(
      companyId: companyId,
      driverId: driverId,
      checkpointSettlementId: checkpointRow == null
          ? null
          : _requiredText(
              checkpointRow[DriverFinanceDbFields.checkpointSettlementId],
            ),
      checkpointPeriodEnd: checkpointRow == null
          ? null
          : _requiredDate(
              checkpointRow[DriverFinanceDbFields.checkpointPeriodEnd],
            ),
      checkpointSnapshotCreatedAt: checkpointRow == null
          ? null
          : _requiredDate(
              checkpointRow[DriverFinanceDbFields.checkpointSnapshotCreatedAt],
            ),
      checkpointClosingBalance: checkpointRow == null
          ? 0
          : _amount(
              checkpointRow[DriverFinanceDbFields.checkpointClosingBalance],
            ),
      totalAdvances: balanceCalculator.roundMoney(totalAdvances),
      totalDriverCharges: balanceCalculator.roundMoney(totalDriverCharges),
      totalTripExpenseCredits: balanceCalculator.roundMoney(
        totalTripExpenseCredits,
      ),
      totalCashReturns: balanceCalculator.roundMoney(totalCashReturns),
    );
  }

  double _positiveAmount(Object? value) {
    final amount = _amount(value);
    if (amount <= 0) {
      throw FormatException('Invalid positive money amount: $value');
    }
    return amount;
  }

  double _amount(Object? value) {
    if (value is num) return value.toDouble();
    final parsed = double.tryParse(value?.toString() ?? '');
    if (parsed == null) {
      throw FormatException('Invalid money amount: $value');
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

  DateTime _requiredDate(Object? value) {
    final parsed = DateTime.tryParse(value?.toString() ?? '');
    if (parsed == null) throw FormatException('Invalid date value: $value');
    return parsed;
  }
}

extension DriverBalanceModelMapper on DriverBalanceModel {
  DriverBalance toEntity() {
    final checkpoint = hasCheckpoint
        ? DriverBalanceCheckpoint(
            settlementId: checkpointSettlementId!,
            periodEnd: checkpointPeriodEnd!,
            snapshotCreatedAt: checkpointSnapshotCreatedAt!,
            closingBalance: checkpointClosingBalance,
          )
        : null;

    return DriverBalance(
      companyId: companyId,
      driverId: driverId,
      checkpoint: checkpoint,
      totalAdvances: totalAdvances,
      totalDriverCharges: totalDriverCharges,
      totalTripExpenseCredits: totalTripExpenseCredits,
      totalCashReturns: totalCashReturns,
    );
  }
}
