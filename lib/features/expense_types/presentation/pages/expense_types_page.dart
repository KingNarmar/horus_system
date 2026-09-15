import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../cubit/expense_types_cubit.dart';
import '../cubit/expense_types_state.dart';
import '../localization/expense_types_localizations.dart';
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

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ExpenseTypesCubit, ExpenseTypesState>(
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
