class ExpenseType {
  final String id;
  final String companyId;
  final String name;
  final String? code;
  final bool isActive;
  final bool isLedgerEligible;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ExpenseType({
    required this.id,
    required this.companyId,
    required this.name,
    required this.isActive,
    this.code,
    this.isLedgerEligible = true,
    this.createdAt,
    this.updatedAt,
  });
}
