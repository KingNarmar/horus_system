class CompanyExpenseVoidData {
  final String companyId;
  final String expenseId;
  final String? reason;

  const CompanyExpenseVoidData({
    required this.companyId,
    required this.expenseId,
    this.reason,
  });
}
