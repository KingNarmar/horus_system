import 'trip_expense_paid_by.dart';

class TripExpense {
  final String id;
  final String companyId;
  final String tripId;
  final String? expenseTypeId;
  final String expenseName;
  final double amount;
  final TripExpensePaidBy paidBy;
  final DateTime expenseDate;
  final String? notes;
  final String? expenseTypeName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const TripExpense({
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
}
