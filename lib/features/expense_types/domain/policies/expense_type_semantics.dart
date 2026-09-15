import '../entities/expense_type.dart';

abstract final class ExpenseTypeSemantics {
  static const String otherCode = 'other';

  static bool requiresDescription(ExpenseType expenseType) {
    return expenseType.code == otherCode;
  }
}
