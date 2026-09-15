import '../../../../core/domain/value_objects/business_date.dart';
import '../../../../core/domain/value_objects/money.dart';
import 'expense_attribution.dart';
import 'expense_funding_source.dart';

final class ExpenseLedgerWriteData {
  final String companyId;
  final String expenseTypeId;
  final Money amount;
  final int currencyFractionDigits;
  final BusinessDate expenseDate;
  final ExpenseFundingSource fundingSource;
  final ExpenseAttribution attribution;
  final String? referenceNumber;
  final String? notes;

  const ExpenseLedgerWriteData({
    required this.companyId,
    required this.expenseTypeId,
    required this.amount,
    required this.currencyFractionDigits,
    required this.expenseDate,
    required this.fundingSource,
    required this.attribution,
    this.referenceNumber,
    this.notes,
  });
}
