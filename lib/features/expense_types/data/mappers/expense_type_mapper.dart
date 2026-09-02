import '../../../../core/data/constants/db_common_fields.dart';
import '../../domain/entities/expense_type.dart';
import '../../domain/entities/expense_type_write_data.dart';
import '../constants/expense_type_db_fields.dart';
import '../models/expense_type_model.dart';

extension ExpenseTypeModelMapper on ExpenseTypeModel {
  ExpenseType toEntity() {
    return ExpenseType(
      id: id,
      companyId: companyId,
      name: name,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

extension ExpenseTypeAuditMapper on ExpenseTypeModel {
  Map<String, Object?> toAuditValues() {
    return {
      DbCommonFields.id: id,
      DbCommonFields.companyId: companyId,
      ExpenseTypeDbFields.name: name,
      DbCommonFields.isActive: isActive,
      DbCommonFields.createdBy: createdBy,
      DbCommonFields.updatedBy: updatedBy,
      DbCommonFields.createdAt: createdAt?.toUtc().toIso8601String(),
      DbCommonFields.updatedAt: updatedAt?.toUtc().toIso8601String(),
    };
  }
}

extension ExpenseTypeWriteDataMapper on ExpenseTypeWriteData {
  Map<String, dynamic> toInsertMap() {
    return {
      DbCommonFields.companyId: companyId,
      ExpenseTypeDbFields.name: name,
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return {ExpenseTypeDbFields.name: name};
  }
}
