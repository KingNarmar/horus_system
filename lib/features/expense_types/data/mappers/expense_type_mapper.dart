import '../../domain/entities/expense_type.dart';
import '../models/expense_type_model.dart';

extension ExpenseTypeModelMapper on ExpenseTypeModel {
  ExpenseType toEntity() {
    return ExpenseType(
      id: id,
      companyId: companyId,
      name: name,
      code: code,
      isActive: isActive,
      isLedgerEligible: isLedgerEligible,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
