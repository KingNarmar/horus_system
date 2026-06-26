import 'trip_expense_paid_by.dart';

class TripExpenseWriteData {
  final String companyId;
  final String tripId;
  final String? expenseTypeId;
  final String expenseName;
  final double amount;
  final TripExpensePaidBy paidBy;
  final DateTime expenseDate;
  final String? notes;

  const TripExpenseWriteData({
    required this.companyId,
    required this.tripId,
    required this.expenseName,
    required this.amount,
    required this.paidBy,
    required this.expenseDate,
    this.expenseTypeId,
    this.notes,
  });
}
