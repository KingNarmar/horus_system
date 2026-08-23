import '../../../../core/data/constants/db_common_fields.dart';
import '../../../../core/data/utils/db_timestamp.dart';
import '../../domain/entities/trip_expense.dart';
import '../../domain/entities/trip_expense_paid_by.dart';
import '../../domain/entities/trip_expense_write_data.dart';
import '../constants/trip_expense_db_fields.dart';
import '../models/trip_expense_model.dart';

extension TripExpenseModelMapper on TripExpenseModel {
  TripExpense toEntity() {
    return TripExpense(
      id: id,
      companyId: companyId,
      tripId: tripId,
      expenseTypeId: expenseTypeId,
      expenseName: expenseName,
      amount: amount,
      paidBy: TripExpensePaidByX.fromValue(paidBy),
      expenseDate: expenseDate,
      notes: notes,
      expenseTypeName: expenseTypeName,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, Object?> toAuditValues() {
    return {
      DbCommonFields.id: id,
      DbCommonFields.companyId: companyId,
      TripExpenseDbFields.tripId: tripId,
      TripExpenseDbFields.expenseTypeId: expenseTypeId,
      TripExpenseDbFields.expenseName: expenseName,
      TripExpenseDbFields.amount: amount,
      TripExpenseDbFields.paidBy: paidBy,
      TripExpenseDbFields.expenseDate: _dateOnly(expenseDate),
      TripExpenseDbFields.notes: notes,
      TripExpenseDbFields.expenseTypeNameAlias: expenseTypeName,
      DbCommonFields.createdAt: createdAt?.toUtc().toIso8601String(),
      DbCommonFields.updatedAt: updatedAt?.toUtc().toIso8601String(),
    };
  }
}

extension TripExpenseWriteDataMapper on TripExpenseWriteData {
  Map<String, dynamic> toInsertMap() {
    return {
      DbCommonFields.companyId: companyId,
      TripExpenseDbFields.tripId: tripId,
      TripExpenseDbFields.expenseTypeId: expenseTypeId,
      TripExpenseDbFields.expenseName: expenseName,
      TripExpenseDbFields.amount: amount,
      TripExpenseDbFields.paidBy: paidBy.value,
      TripExpenseDbFields.expenseDate: _dateOnly(expenseDate),
      TripExpenseDbFields.notes: notes,
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      TripExpenseDbFields.expenseTypeId: expenseTypeId,
      TripExpenseDbFields.expenseName: expenseName,
      TripExpenseDbFields.amount: amount,
      TripExpenseDbFields.paidBy: paidBy.value,
      TripExpenseDbFields.expenseDate: _dateOnly(expenseDate),
      TripExpenseDbFields.notes: notes,
      DbCommonFields.updatedAt: DbTimestamp.nowUtcIsoString(),
    };
  }
}

String _dateOnly(DateTime value) {
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '${value.year}-$month-$day';
}
