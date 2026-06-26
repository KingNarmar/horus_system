class TripExpenseModel {
  final String id;
  final String companyId;
  final String tripId;
  final String? expenseTypeId;
  final String expenseName;
  final double amount;
  final String paidBy;
  final DateTime expenseDate;
  final String? notes;
  final String? expenseTypeName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const TripExpenseModel({
    required this.id,
    required this.companyId,
    required this.tripId,
    required this.expenseName,
    required this.amount,
    required this.paidBy,
    required this.expenseDate,
    this.expenseTypeId,
    this.notes,
    this.expenseTypeName,
    this.createdAt,
    this.updatedAt,
  });

  factory TripExpenseModel.fromMap(Map<String, dynamic> map) {
    return TripExpenseModel(
      id: map['id'] as String,
      companyId: map['company_id'] as String,
      tripId: map['trip_id'] as String,
      expenseTypeId: map['expense_type_id'] as String?,
      expenseName: map['expense_name'] as String? ?? '',
      amount: _toDouble(map['amount']) ?? 0,
      paidBy: map['paid_by'] as String? ?? 'company',
      expenseDate: _toDateTime(map['expense_date']) ?? DateTime.now(),
      notes: map['notes'] as String?,
      expenseTypeName:
          map['expense_type_name'] as String? ??
          _nestedString(map['expense_type'], 'name') ??
          _nestedString(map['expense_types'], 'name'),
      createdAt: _toDateTime(map['created_at']),
      updatedAt: _toDateTime(map['updated_at']),
    );
  }

  static DateTime? _toDateTime(Object? value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  static double? _toDouble(Object? value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static String? _nestedString(Object? value, String key) {
    if (value is! Map) return null;
    final nestedValue = value[key];
    if (nestedValue == null) return null;
    final text = nestedValue.toString().trim();
    return text.isEmpty ? null : text;
  }
}
