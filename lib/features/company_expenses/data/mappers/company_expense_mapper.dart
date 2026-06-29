import '../../../../core/data/constants/db_common_fields.dart';
import '../../../../core/data/utils/db_timestamp.dart';
import '../../domain/entities/company_expense.dart';
import '../../domain/entities/company_expense_void_data.dart';
import '../../domain/entities/company_expense_write_data.dart';
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
        'category_id': categoryId,
        'driver_id': driverId,
        'tractor_head_id': tractorHeadId,
        'trailer_id': trailerId,
        'trip_id': tripId,
        'amount': amount,
        'expense_date': _dateOnly(expenseDate),
        'reference_number': referenceNumber,
        'notes': notes,
        'is_voided': isVoided,
        'voided_at': voidedAt?.toUtc().toIso8601String(),
        'voided_by': voidedBy,
        'void_reason': voidReason,
        DbCommonFields.createdAt: createdAt?.toUtc().toIso8601String(),
        DbCommonFields.updatedAt: updatedAt?.toUtc().toIso8601String(),
      };
}

extension CompanyExpenseWriteDataMapper on CompanyExpenseWriteData {
  Map<String, dynamic> toInsertMap() => {
        DbCommonFields.companyId: companyId,
        'category_id': categoryId,
        'driver_id': driverId,
        'tractor_head_id': tractorHeadId,
        'trailer_id': trailerId,
        'trip_id': tripId,
        'amount': amount,
        'expense_date': _dateOnly(expenseDate),
        'reference_number': referenceNumber,
        'notes': notes,
      };

  Map<String, dynamic> toUpdateMap() => {
        'category_id': categoryId,
        'driver_id': driverId,
        'tractor_head_id': tractorHeadId,
        'trailer_id': trailerId,
        'trip_id': tripId,
        'amount': amount,
        'expense_date': _dateOnly(expenseDate),
        'reference_number': referenceNumber,
        'notes': notes,
        DbCommonFields.updatedAt: DbTimestamp.nowUtcIsoString(),
      };
}

extension CompanyExpenseVoidDataMapper on CompanyExpenseVoidData {
  Map<String, dynamic> toVoidMap({required String? actorUserId}) => {
        'is_voided': true,
        'voided_at': DbTimestamp.nowUtcIsoString(),
        'voided_by': actorUserId,
        'void_reason': reason,
        DbCommonFields.updatedAt: DbTimestamp.nowUtcIsoString(),
        'updated_by': actorUserId,
      };
}

String _dateOnly(DateTime value) {
  final utc = value.toUtc();
  return '${utc.year.toString().padLeft(4, '0')}-'
      '${utc.month.toString().padLeft(2, '0')}-'
      '${utc.day.toString().padLeft(2, '0')}';
}
