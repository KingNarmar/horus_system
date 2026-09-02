import '../../../../core/data/constants/db_common_fields.dart';

abstract final class TripExpenseDbFields {
  static const tableName = 'trip_expenses';

  static const tripId = 'trip_id';
  static const expenseTypeId = 'expense_type_id';
  static const expenseName = 'expense_name';
  static const amount = 'amount';
  static const paidBy = 'paid_by';
  static const expenseDate = 'expense_date';
  static const notes = 'notes';

  static const expenseTypeNameAlias = 'expense_type_name';
  static const expenseTypeRelationKey = 'expense_type';

  static const allColumns =
      '${DbCommonFields.id}, ${DbCommonFields.companyId}, $tripId, '
      '$expenseTypeId, $expenseName, $amount, $paidBy, $expenseDate, $notes, '
      '${DbCommonFields.createdAt}, ${DbCommonFields.updatedAt}, '
      '${TripExpenseTypeRelationDbFields.relationName}!'
      'trip_expenses_company_type_fk(${TripExpenseTypeRelationDbFields.name})';
}

abstract final class TripExpenseTypeRelationDbFields {
  static const relationName = 'expense_types';
  static const name = 'name';
}

abstract final class TripExpenseLinkedTripDbFields {
  static const tableName = 'trips';
  static const totalExpenses = 'total_expenses';
}
