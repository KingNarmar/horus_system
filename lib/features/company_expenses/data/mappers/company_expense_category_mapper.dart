import '../../domain/entities/company_expense_category.dart';
import '../models/company_expense_category_model.dart';

extension CompanyExpenseCategoryModelMapper on CompanyExpenseCategoryModel {
  CompanyExpenseCategory toEntity() {
    return CompanyExpenseCategory(
      id: id,
      companyId: companyId,
      name: name,
      code: code,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
