import '../../../../core/domain/value_objects/business_date.dart';
import '../../../../core/domain/value_objects/money.dart';
import 'expense_attribution.dart';
import 'expense_funding_source.dart';

final class ExpenseLedgerEntry {
  final String id;
  final String companyId;
  final String expenseTypeId;
  final Money amount;
  final int currencyFractionDigits;
  final BusinessDate expenseDate;
  final ExpenseFundingSource fundingSource;
  final ExpenseAttribution attribution;
  final String? description;
  final String? referenceNumber;
  final String? notes;
  final bool isVoided;
  final DateTime? voidedAt;
  final String? voidedBy;
  final String? voidReason;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ExpenseLedgerEntry({
    required this.id,
    required this.companyId,
    required this.expenseTypeId,
    required this.amount,
    required this.currencyFractionDigits,
    required this.expenseDate,
    required this.fundingSource,
    required this.attribution,
    required this.isVoided,
    this.description,
    this.referenceNumber,
    this.notes,
    this.voidedAt,
    this.voidedBy,
    this.voidReason,
    this.createdAt,
    this.updatedAt,
  });
}
