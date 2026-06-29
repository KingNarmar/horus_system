import 'package:flutter/material.dart';

import '../../domain/entities/company_expense.dart';
import '../../domain/entities/company_expense_category.dart';

class CompanyExpenseFormData {
  final String categoryId;
  final double amount;
  final DateTime expenseDate;
  final String? referenceNumber;
  final String? notes;

  const CompanyExpenseFormData({
    required this.categoryId,
    required this.amount,
    required this.expenseDate,
    this.referenceNumber,
    this.notes,
  });
}

class CompanyExpenseFormDialog extends StatelessWidget {
  final List<CompanyExpenseCategory> categories;
  final CompanyExpense? expense;
  final Future<void> Function(CompanyExpenseFormData data) onSubmit;

  const CompanyExpenseFormDialog({
    required this.categories,
    required this.onSubmit,
    this.expense,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
