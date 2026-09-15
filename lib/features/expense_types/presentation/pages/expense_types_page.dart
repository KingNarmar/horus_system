import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../../domain/entities/expense_type.dart';
import '../cubit/expense_types_cubit.dart';
import '../cubit/expense_types_state.dart';
import '../helpers/expense_types_failure_message.dart';
import '../localization/expense_types_localizations.dart';
import '../widgets/expense_type_form_dialog.dart';
import '../widgets/expense_types_state_view.dart';

class ExpenseTypesPage extends StatefulWidget {
  final CurrentCompanyContext currentCompanyContext;

  const ExpenseTypesPage({required this.currentCompanyContext, super.key});

  @override
  State<ExpenseTypesPage> createState() => _ExpenseTypesPageState();
}

class _ExpenseTypesPageState extends State<ExpenseTypesPage> {
  @override
  void initState() {
    super.initState();
    context.read<ExpenseTypesCubit>().loadExpenseTypes(
      widget.currentCompanyContext,
    );
  }

  @override
  void didUpdateWidget(covariant ExpenseTypesPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentCompanyContext.companyId !=
            widget.currentCompanyContext.companyId ||
        oldWidget.currentCompanyContext.role !=
            widget.currentCompanyContext.role) {
      context.read<ExpenseTypesCubit>().loadExpenseTypes(
        widget.currentCompanyContext,
      );
    }
  }

  Future<void> _openEditForm(ExpenseType expenseType) async {
    final cubit = context.read<ExpenseTypesCubit>();
    await showDialog<void>(
      context: context,
      builder: (_) => ExpenseTypeFormDialog(
        expenseType: expenseType,
        onSubmit: (name) {
          return cubit.updateExpenseType(expenseType: expenseType, name: name);
        },
      ),
    );
  }

  Future<void> _deactivate(ExpenseType expenseType) async {
    final l10n = context.expenseTypesL10n;
    final confirmed = await _confirm(
      title: l10n.confirmDeactivateTitle,
      body: l10n.confirmDeactivateBody,
      confirmLabel: l10n.deactivate,
    );
    if (confirmed && mounted) {
      await context.read<ExpenseTypesCubit>().deactivateExpenseType(
        expenseType,
      );
    }
  }

  Future<void> _reactivate(ExpenseType expenseType) async {
    final l10n = context.expenseTypesL10n;
    final confirmed = await _confirm(
      title: l10n.confirmReactivateTitle,
      body: l10n.confirmReactivateBody,
      confirmLabel: l10n.reactivate,
    );
    if (confirmed && mounted) {
      await context.read<ExpenseTypesCubit>().reactivateExpenseType(
        expenseType,
      );
    }
  }

  Future<bool> _confirm({
    required String title,
    required String body,
    required String confirmLabel,
  }) async {
    final l10n = context.expenseTypesL10n;
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(title),
            content: Text(body),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(confirmLabel),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showFeedback(ExpenseTypesLoaded state) {
    final l10n = context.expenseTypesL10n;
    final message = state.mutationFailure != null
        ? expenseTypesFailureMessage(state.mutationFailure!, l10n)
        : switch (state.completedMutation) {
            ExpenseTypeMutation.updated => l10n.updatedSuccess,
            ExpenseTypeMutation.deactivated => l10n.deactivatedSuccess,
            ExpenseTypeMutation.reactivated => l10n.reactivatedSuccess,
            null => null,
          };
    if (message == null) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ExpenseTypesCubit, ExpenseTypesState>(
      listenWhen: (previous, current) {
        if (current is! ExpenseTypesLoaded) return false;
        final previousSequence = previous is ExpenseTypesLoaded
            ? previous.feedbackSequence
            : -1;
        return current.feedbackSequence != previousSequence &&
            current.feedbackSequence > 0;
      },
      listener: (context, state) {
        if (state is ExpenseTypesLoaded) _showFeedback(state);
      },
      builder: (context, state) {
        final cubit = context.read<ExpenseTypesCubit>();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _PageHeader(),
            const SizedBox(height: AppSpacing.lg),
            ExpenseTypesStateView(
              state: state,
              onRetry: () =>
                  cubit.loadExpenseTypes(widget.currentCompanyContext),
              onStatusFilterChanged: cubit.setStatusFilter,
              onEdit: _openEditForm,
              onDeactivate: _deactivate,
              onReactivate: _reactivate,
            ),
          ],
        );
      },
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader();

  @override
  Widget build(BuildContext context) {
    final l10n = context.expenseTypesL10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.title,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(l10n.description),
      ],
    );
  }
}
