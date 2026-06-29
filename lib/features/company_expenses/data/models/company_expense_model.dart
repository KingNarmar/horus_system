class CompanyExpenseModel {
  final String id;
  final String companyId;
  final String categoryId;
  final double amount;
  final DateTime expenseDate;
  final bool isVoided;

  const CompanyExpenseModel({
    required this.id,
    required this.companyId,
    required this.categoryId,
    required this.amount,
    required this.expenseDate,
    required this.isVoided,
  });
}
