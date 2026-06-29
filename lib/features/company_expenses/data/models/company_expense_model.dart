class CompanyExpenseModel {
  final String id;
  final String companyId;
  final String categoryId;
  final String? driverId;
  final String? tractorHeadId;
  final String? trailerId;
  final String? tripId;
  final double amount;
  final DateTime expenseDate;
  final String? referenceNumber;
  final String? notes;
  final bool isVoided;
  final DateTime? voidedAt;
  final String? voidedBy;
  final String? voidReason;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CompanyExpenseModel({
    required this.id,
    required this.companyId,
    required this.categoryId,
    required this.amount,
    required this.expenseDate,
    required this.isVoided,
    this.driverId,
    this.tractorHeadId,
    this.trailerId,
    this.tripId,
    this.referenceNumber,
    this.notes,
    this.voidedAt,
    this.voidedBy,
    this.voidReason,
    this.createdAt,
    this.updatedAt,
  });

  factory CompanyExpenseModel.fromMap(Map<String, dynamic> map) {
    return CompanyExpenseModel(
      id: map['id'] as String,
      companyId: map['company_id'] as String,
      categoryId: map['category_id'] as String,
      amount: map['amount'] is num ? (map['amount'] as num).toDouble() : 0,
      expenseDate: DateTime.tryParse(map['expense_date'].toString()) ?? DateTime.now(),
      isVoided: map['is_voided'] as bool? ?? false,
    );
  }
}
