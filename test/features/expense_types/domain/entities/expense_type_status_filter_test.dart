import 'package:horus_system/features/expense_types/domain/entities/expense_type.dart';
import 'package:horus_system/features/expense_types/domain/entities/expense_type_status_filter.dart';
import 'package:test/test.dart';

void main() {
  const active = ExpenseType(
    id: 'active',
    companyId: 'company-1',
    name: 'Fuel',
    isActive: true,
  );
  const inactive = ExpenseType(
    id: 'inactive',
    companyId: 'company-1',
    name: 'Road fees',
    isActive: false,
  );

  test('status filters match lifecycle state', () {
    expect(ExpenseTypeStatusFilter.active.matches(active), isTrue);
    expect(ExpenseTypeStatusFilter.active.matches(inactive), isFalse);
    expect(ExpenseTypeStatusFilter.inactive.matches(active), isFalse);
    expect(ExpenseTypeStatusFilter.inactive.matches(inactive), isTrue);
    expect(ExpenseTypeStatusFilter.all.matches(active), isTrue);
    expect(ExpenseTypeStatusFilter.all.matches(inactive), isTrue);
  });
}
