import 'expense_type.dart';

enum ExpenseTypeStatusFilter { active, inactive, all }

extension ExpenseTypeStatusFilterX on ExpenseTypeStatusFilter {
  bool matches(ExpenseType type) {
    return switch (this) {
      ExpenseTypeStatusFilter.active => type.isActive,
      ExpenseTypeStatusFilter.inactive => !type.isActive,
      ExpenseTypeStatusFilter.all => true,
    };
  }
}
