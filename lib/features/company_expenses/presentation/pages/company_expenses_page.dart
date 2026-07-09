import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../../domain/entities/company_expense.dart';
import '../cubit/company_expenses_cubit.dart';
import '../cubit/company_expenses_state.dart';
import '../widgets/company_expense_details_dialog.dart';
import '../widgets/company_expense_form_dialog.dart';
import '../widgets/company_expenses_state_view.dart';

class CompanyExpensesPage extends StatefulWidget {
  final CurrentCompanyContext currentCompanyContext;

  const CompanyExpensesPage({required this.currentCompanyContext, super.key});

  @override
  State<CompanyExpensesPage> createState() => _CompanyExpensesPageState();
}

class _CompanyExpensesPageState extends State<CompanyExpensesPage> {
  @override
  void initState() {
    super.initState();
    context.read<CompanyExpensesCubit>().loadCompanyExpenses(
      widget.currentCompanyContext,
    );
  }

  Future<void> _openExpenseForm({CompanyExpense? expense}) async {
    final state = context.read<CompanyExpensesCubit>().state;
    if (state is! CompanyExpensesLoaded) return;

    await showDialog<void>(
      context: context,
      builder: (_) => CompanyExpenseFormDialog(
        categories: state.categories,
        formLookups: state.formLookups,
        expense: expense,
        onSubmit: (data) {
          final cubit = context.read<CompanyExpensesCubit>();
          if (expense == null) {
            return cubit.addExpense(
              categoryId: data.categoryId,
              amount: data.amount,
              expenseDate: data.expenseDate,
              driverId: data.driverId,
              tractorHeadId: data.tractorHeadId,
              trailerId: data.trailerId,
              tripId: data.tripId,
              referenceNumber: data.referenceNumber,
              notes: data.notes,
            );
          }
          return cubit.updateExpense(
            expense: expense,
            categoryId: data.categoryId,
            amount: data.amount,
            expenseDate: data.expenseDate,
            driverId: data.driverId,
            tractorHeadId: data.tractorHeadId,
            trailerId: data.trailerId,
            tripId: data.tripId,
            referenceNumber: data.referenceNumber,
            notes: data.notes,
          );
        },
      ),
    );
  }

  Future<void> _openExpenseDetails(CompanyExpense expense) async {
    final cubit = context.read<CompanyExpensesCubit>();
    cubit.loadExpenseActivity(expense);
    await showDialog<void>(
      context: context,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: BlocBuilder<CompanyExpensesCubit, CompanyExpensesState>(
          builder: (context, state) => CompanyExpenseDetailsDialog(
            expense: expense,
            state: state is CompanyExpensesLoaded ? state : null,
          ),
        ),
      ),
    );
    cubit.clearExpenseActivity();
  }

  Future<void> _confirmVoidExpense(CompanyExpense expense) async {
    final cubit = context.read<CompanyExpensesCubit>();
    final reasonController = TextEditingController();
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) {
          final l10n = context.l10n;
          return AlertDialog(
            title: Text(l10n.voidCompanyExpenseTitle),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.voidCompanyExpenseMessage),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: reasonController,
                  decoration: InputDecoration(labelText: l10n.voidReasonLabel),
                  maxLines: 2,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(l10n.cancelButton),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(l10n.confirmButton),
              ),
            ],
          );
        },
      );

      if (confirmed != true) return;
      final reason = reasonController.text.trim();
      await cubit.voidExpense(expense, reason: reason.isEmpty ? null : reason);
    } finally {
      reasonController.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocBuilder<CompanyExpensesCubit, CompanyExpensesState>(
      builder: (context, state) {
        final cubit = context.read<CompanyExpensesCubit>();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.companyExpensesTitle,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (state is CompanyExpensesLoaded &&
                    state.canManageCompanyExpenses)
                  FilledButton.icon(
                    onPressed: () => _openExpenseForm(),
                    icon: const Icon(AppIcons.add),
                    label: Text(l10n.addCompanyExpenseButton),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            CompanyExpensesStateView(
              state: state,
              onRetry: () =>
                  cubit.loadCompanyExpenses(widget.currentCompanyContext),
              onSearchChanged: cubit.setSearchQuery,
              onIncludeVoidedChanged: cubit.setIncludeVoided,
              onViewDetails: _openExpenseDetails,
              onEdit: (expense) => _openExpenseForm(expense: expense),
              onVoid: _confirmVoidExpense,
            ),
          ],
        );
      },
    );
  }
}
