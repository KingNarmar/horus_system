import '../../../../core/data/constants/db_common_fields.dart';
import '../constants/trip_expense_db_fields.dart';

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
      id: map[DbCommonFields.id] as String,
      companyId: map[DbCommonFields.companyId] as String,
      tripId: map[TripExpenseDbFields.tripId] as String,
      expenseTypeId: map[TripExpenseDbFields.expenseTypeId] as String?,
      expenseName: map[TripExpenseDbFields.expenseName] as String? ?? '',
      amount: _toDouble(map[TripExpenseDbFields.amount]) ?? 0,
      paidBy: map[TripExpenseDbFields.paidBy] as String? ?? 'company',
      expenseDate:
          _toDateTime(map[TripExpenseDbFields.expenseDate]) ?? DateTime.now(),
      notes: map[TripExpenseDbFields.notes] as String?,
      expenseTypeName:
          map[TripExpenseDbFields.expenseTypeNameAlias] as String? ??
          _nestedString(
            map[TripExpenseDbFields.expenseTypeRelationKey],
            TripExpenseTypeRelationDbFields.name,
          ) ??
          _nestedString(
            map[TripExpenseTypeRelationDbFields.relationName],
            TripExpenseTypeRelationDbFields.name,
          ),
      createdAt: _toDateTime(map[DbCommonFields.createdAt]),
      updatedAt: _toDateTime(map[DbCommonFields.updatedAt]),
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
