import '../../../../core/data/constants/db_common_fields.dart';
import '../../../../core/data/utils/db_timestamp.dart';
import '../../domain/entities/company_expense.dart';
import '../../domain/entities/company_expense_void_data.dart';
import '../../domain/entities/company_expense_write_data.dart';
import '../constants/company_expense_db_fields.dart';
import '../models/company_expense_model.dart';

extension CompanyExpenseModelMapper on CompanyExpenseModel {
  CompanyExpense toEntity() => CompanyExpense(
    id: id,
    companyId: companyId,
    categoryId: categoryId,
    amount: amount,
    expenseDate: expenseDate,
    isVoided: isVoided,
    driverId: driverId,
    tractorHeadId: tractorHeadId,
    trailerId: trailerId,
    tripId: tripId,
    referenceNumber: referenceNumber,
    notes: notes,
    voidedAt: voidedAt,
    voidedBy: voidedBy,
    voidReason: voidReason,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );

  Map<String, Object?> toAuditValues() => {
    DbCommonFields.id: id,
    DbCommonFields.companyId: companyId,
    CompanyExpenseDbFields.categoryId: categoryId,
    CompanyExpenseDbFields.driverId: driverId,
    CompanyExpenseDbFields.tractorHeadId: tractorHeadId,
    CompanyExpenseDbFields.trailerId: trailerId,
    CompanyExpenseDbFields.tripId: tripId,
    CompanyExpenseDbFields.amount: amount,
    CompanyExpenseDbFields.expenseDate: _dateOnly(expenseDate),
    CompanyExpenseDbFields.referenceNumber: referenceNumber,
    CompanyExpenseDbFields.notes: notes,
    CompanyExpenseDbFields.isVoided: isVoided,
    CompanyExpenseDbFields.voidedAt: voidedAt?.toUtc().toIso8601String(),
    CompanyExpenseDbFields.voidedBy: voidedBy,
    CompanyExpenseDbFields.voidReason: voidReason,
    DbCommonFields.createdAt: createdAt?.toUtc().toIso8601String(),
    DbCommonFields.updatedAt: updatedAt?.toUtc().toIso8601String(),
  };
}

extension CompanyExpenseWriteDataMapper on CompanyExpenseWriteData {
  Map<String, dynamic> toInsertMap() => {
    DbCommonFields.companyId: companyId,
    CompanyExpenseDbFields.categoryId: categoryId,
    CompanyExpenseDbFields.driverId: driverId,
    CompanyExpenseDbFields.tractorHeadId: tractorHeadId,
    CompanyExpenseDbFields.trailerId: trailerId,
    CompanyExpenseDbFields.tripId: tripId,
    CompanyExpenseDbFields.amount: amount,
    CompanyExpenseDbFields.expenseDate: _dateOnly(expenseDate),
    CompanyExpenseDbFields.referenceNumber: referenceNumber,
    CompanyExpenseDbFields.notes: notes,
  };

  Map<String, dynamic> toUpdateMap() => {
    CompanyExpenseDbFields.categoryId: categoryId,
    CompanyExpenseDbFields.driverId: driverId,
    CompanyExpenseDbFields.tractorHeadId: tractorHeadId,
    CompanyExpenseDbFields.trailerId: trailerId,
    CompanyExpenseDbFields.tripId: tripId,
    CompanyExpenseDbFields.amount: amount,
    CompanyExpenseDbFields.expenseDate: _dateOnly(expenseDate),
    CompanyExpenseDbFields.referenceNumber: referenceNumber,
    CompanyExpenseDbFields.notes: notes,
    DbCommonFields.updatedAt: DbTimestamp.nowUtcIsoString(),
  };
}

extension CompanyExpenseVoidDataMapper on CompanyExpenseVoidData {
  Map<String, dynamic> toVoidMap({required String? actorUserId}) => {
    CompanyExpenseDbFields.isVoided: true,
    CompanyExpenseDbFields.voidedAt: DbTimestamp.nowUtcIsoString(),
    CompanyExpenseDbFields.voidedBy: actorUserId,
    CompanyExpenseDbFields.voidReason: reason,
    DbCommonFields.updatedAt: DbTimestamp.nowUtcIsoString(),
    DbCommonFields.updatedBy: actorUserId,
  };
}

String _dateOnly(DateTime value) {
  final utc = value.toUtc();
  return '${utc.year.toString().padLeft(4, '0')}-'
      '${utc.month.toString().padLeft(2, '0')}-'
      '${utc.day.toString().padLeft(2, '0')}';
}
