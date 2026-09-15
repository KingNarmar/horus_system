import '../../../../core/domain/value_objects/business_date.dart';
import '../../../../core/domain/value_objects/currency_code.dart';
import '../../../../core/domain/value_objects/money.dart';
import '../../domain/entities/expense_attribution.dart';
import '../../domain/entities/expense_funding_source.dart';
import '../../domain/entities/expense_ledger_entry.dart';
import '../../domain/entities/expense_ledger_write_data.dart';
import '../constants/expense_ledger_rpc_constants.dart';
import '../models/expense_ledger_entry_model.dart';

extension ExpenseLedgerEntryModelMapper on ExpenseLedgerEntryModel {
  ExpenseLedgerEntry toEntity() {
    final currency = CurrencyCode.tryParse(currencyCode);
    if (currency == null) {
      throw const FormatException('Invalid expense currency code.');
    }

    return ExpenseLedgerEntry(
      id: id,
      companyId: companyId,
      expenseTypeId: expenseTypeId,
      amount: Money(minorUnits: amountMinorUnits, currency: currency),
      currencyFractionDigits: currencyFractionDigits,
      expenseDate: _parseBusinessDate(expenseDate),
      fundingSource: _fundingSourceFromDb(fundingSource),
      attribution: ExpenseAttribution(
        tripId: tripId,
        driverId: driverId,
        tractorHeadId: tractorHeadId,
        trailerId: trailerId,
      ),
      description: description,
      referenceNumber: referenceNumber,
      notes: notes,
      isVoided: isVoided,
      voidedAt: voidedAt,
      voidedBy: voidedBy,
      voidReason: voidReason,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

extension ExpenseLedgerWriteDataMapper on ExpenseLedgerWriteData {
  Map<String, dynamic> toCreateRpcParams() {
    return {
      ExpenseLedgerRpcConstants.companyId: companyId,
      ExpenseLedgerRpcConstants.expenseTypeId: expenseTypeId,
      ExpenseLedgerRpcConstants.amountMinorUnits: amount.minorUnits,
      ExpenseLedgerRpcConstants.currencyCode: amount.currency.value,
      ExpenseLedgerRpcConstants.currencyFractionDigits: currencyFractionDigits,
      ExpenseLedgerRpcConstants.expenseDate: _businessDateToIso(expenseDate),
      ExpenseLedgerRpcConstants.fundingSource: _fundingSourceToDb(
        fundingSource,
      ),
      ExpenseLedgerRpcConstants.tripId: attribution.tripId,
      ExpenseLedgerRpcConstants.driverId: attribution.driverId,
      ExpenseLedgerRpcConstants.tractorHeadId: attribution.tractorHeadId,
      ExpenseLedgerRpcConstants.trailerId: attribution.trailerId,
      ExpenseLedgerRpcConstants.description: description,
      ExpenseLedgerRpcConstants.referenceNumber: referenceNumber,
      ExpenseLedgerRpcConstants.notes: notes,
    };
  }
}

ExpenseFundingSource _fundingSourceFromDb(String value) {
  return switch (value) {
    'company' => ExpenseFundingSource.company,
    'driver_advance' => ExpenseFundingSource.driverAdvance,
    'driver_cash' => ExpenseFundingSource.driverCash,
    'customer' => ExpenseFundingSource.customer,
    'other' => ExpenseFundingSource.other,
    _ => throw FormatException('Unsupported expense funding source: $value'),
  };
}

String _fundingSourceToDb(ExpenseFundingSource value) {
  return switch (value) {
    ExpenseFundingSource.company => 'company',
    ExpenseFundingSource.driverAdvance => 'driver_advance',
    ExpenseFundingSource.driverCash => 'driver_cash',
    ExpenseFundingSource.customer => 'customer',
    ExpenseFundingSource.other => 'other',
  };
}

BusinessDate _parseBusinessDate(String value) {
  final parts = value.split('-');
  if (parts.length != 3) throw const FormatException('Invalid business date.');

  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final day = int.tryParse(parts[2]);
  if (year == null || month == null || day == null) {
    throw const FormatException('Invalid business date.');
  }

  final date = BusinessDate.tryCreate(year: year, month: month, day: day);
  if (date == null) throw const FormatException('Invalid business date.');
  return date;
}

String _businessDateToIso(BusinessDate value) {
  final year = value.year.toString().padLeft(4, '0');
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}
