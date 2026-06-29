import '../../domain/entities/company_expense.dart';
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
}
