import '../../domain/entities/company_expense.dart';
import '../models/company_expense_model.dart';

extension CompanyExpenseModelMapper on CompanyExpenseModel {
  CompanyExpense toEntity() {
    return CompanyExpense(
      id: id,
      companyId: companyId,
      categoryId: categoryId,
      amount: amount,
      expenseDate: expenseDate,
      isVoided: isVoided,
    );
  }
}
