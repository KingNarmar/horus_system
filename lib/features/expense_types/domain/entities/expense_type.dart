class ExpenseType {
  final String id;
  final String companyId;
  final String name;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ExpenseType({
    required this.id,
    required this.companyId,
    required this.name,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });
}
