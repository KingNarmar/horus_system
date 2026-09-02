import 'package:flutter/material.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../domain/entities/expense_type.dart';
import '../../domain/entities/expense_type_status_filter.dart';
import '../cubit/expense_types_state.dart';
import '../helpers/expense_types_failure_message.dart';
import '../localization/expense_types_localizations.dart';

class ExpenseTypesStateView extends StatelessWidget {
  final ExpenseTypesState state;
  final VoidCallback onRetry;
  final ValueChanged<ExpenseTypeStatusFilter> onStatusFilterChanged;
  final ValueChanged<ExpenseType> onEdit;
  final ValueChanged<ExpenseType> onDeactivate;
  final ValueChanged<ExpenseType> onReactivate;

  const ExpenseTypesStateView({
    required this.state,
    required this.onRetry,
    required this.onStatusFilterChanged,
    required this.onEdit,
    required this.onDeactivate,
    required this.onReactivate,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.expenseTypesL10n;
    return switch (state) {
      ExpenseTypesInitial() || ExpenseTypesLoading() => _Loading(l10n: l10n),
      ExpenseTypesFailure(:final failure) => _Failure(
        message: expenseTypesFailureMessage(failure, l10n),
        onRetry: onRetry,
        l10n: l10n,
      ),
      ExpenseTypesLoaded() => _Loaded(
        state: state as ExpenseTypesLoaded,
        onStatusFilterChanged: onStatusFilterChanged,
        onEdit: onEdit,
        onDeactivate: onDeactivate,
        onReactivate: onReactivate,
      ),
    };
  }
}

class _Loading extends StatelessWidget {
  final ExpenseTypesLocalizations l10n;

  const _Loading({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Column(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: AppSpacing.md),
          Text(l10n.loading),
        ],
      ),
    );
  }
}

class _Failure extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final ExpenseTypesLocalizations l10n;

  const _Failure({
    required this.message,
    required this.onRetry,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(message),
        const SizedBox(height: AppSpacing.md),
        OutlinedButton(onPressed: onRetry, child: Text(l10n.retry)),
      ],
    );
  }
}

class _Loaded extends StatelessWidget {
  final ExpenseTypesLoaded state;
  final ValueChanged<ExpenseTypeStatusFilter> onStatusFilterChanged;
  final ValueChanged<ExpenseType> onEdit;
  final ValueChanged<ExpenseType> onDeactivate;
  final ValueChanged<ExpenseType> onReactivate;

  const _Loaded({
    required this.state,
    required this.onStatusFilterChanged,
    required this.onEdit,
    required this.onDeactivate,
    required this.onReactivate,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.expenseTypesL10n;
    final types = state.visibleTypes;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: ExpenseTypeStatusFilter.values
              .map(
                (filter) => FilterChip(
                  label: Text(_filterLabel(filter, l10n)),
                  selected: state.statusFilter == filter,
                  onSelected: (_) => onStatusFilterChanged(filter),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (types.isEmpty)
          Text(state.allTypes.isEmpty ? l10n.noTypes : l10n.noFilteredTypes)
        else
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= AppSizes.dataTableBreakpoint) {
                return _TypesTable(
                  types: types,
                  state: state,
                  onEdit: onEdit,
                  onDeactivate: onDeactivate,
                  onReactivate: onReactivate,
                );
              }
              return _TypesCards(
                types: types,
                state: state,
                onEdit: onEdit,
                onDeactivate: onDeactivate,
                onReactivate: onReactivate,
              );
            },
          ),
      ],
    );
  }

  String _filterLabel(
    ExpenseTypeStatusFilter filter,
    ExpenseTypesLocalizations l10n,
  ) {
    return switch (filter) {
      ExpenseTypeStatusFilter.active => l10n.active,
      ExpenseTypeStatusFilter.inactive => l10n.inactive,
      ExpenseTypeStatusFilter.all => l10n.all,
    };
  }
}

class _TypesTable extends StatelessWidget {
  final List<ExpenseType> types;
  final ExpenseTypesLoaded state;
  final ValueChanged<ExpenseType> onEdit;
  final ValueChanged<ExpenseType> onDeactivate;
  final ValueChanged<ExpenseType> onReactivate;

  const _TypesTable({
    required this.types,
    required this.state,
    required this.onEdit,
    required this.onDeactivate,
    required this.onReactivate,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.expenseTypesL10n;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          DataColumn(label: Text(l10n.nameLabel)),
          DataColumn(label: Text(l10n.status)),
          if (state.canManageExpenseTypes)
            DataColumn(label: Text(l10n.actions)),
        ],
        rows: types
            .map(
              (type) => DataRow(
                cells: [
                  DataCell(Text(type.name)),
                  DataCell(
                    Chip(label: Text(type.isActive ? l10n.active : l10n.inactive)),
                  ),
                  if (state.canManageExpenseTypes)
                    DataCell(
                      _TypeActions(
                        type: type,
                        state: state,
                        onEdit: onEdit,
                        onDeactivate: onDeactivate,
                        onReactivate: onReactivate,
                      ),
                    ),
                ],
              ),
            )
            .toList(),
      ),
    );
  }
}

class _TypesCards extends StatelessWidget {
  final List<ExpenseType> types;
  final ExpenseTypesLoaded state;
  final ValueChanged<ExpenseType> onEdit;
  final ValueChanged<ExpenseType> onDeactivate;
  final ValueChanged<ExpenseType> onReactivate;

  const _TypesCards({
    required this.types,
    required this.state,
    required this.onEdit,
    required this.onDeactivate,
    required this.onReactivate,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.expenseTypesL10n;
    return Column(
      children: types
          .map(
            (type) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              type.name,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(type.isActive ? l10n.active : l10n.inactive),
                          ],
                        ),
                      ),
                      if (state.canManageExpenseTypes)
                        _TypeActions(
                          type: type,
                          state: state,
                          onEdit: onEdit,
                          onDeactivate: onDeactivate,
                          onReactivate: onReactivate,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _TypeActions extends StatelessWidget {
  final ExpenseType type;
  final ExpenseTypesLoaded state;
  final ValueChanged<ExpenseType> onEdit;
  final ValueChanged<ExpenseType> onDeactivate;
  final ValueChanged<ExpenseType> onReactivate;

  const _TypeActions({
    required this.type,
    required this.state,
    required this.onEdit,
    required this.onDeactivate,
    required this.onReactivate,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.expenseTypesL10n;
    final isPending = state.pendingActionExpenseTypeId == type.id;
    if (isPending) {
      return const SizedBox(
        width: AppSizes.loadingIndicatorSm,
        height: AppSizes.loadingIndicatorSm,
        child: CircularProgressIndicator(
          strokeWidth: AppSizes.loadingIndicatorStrokeWidth,
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: l10n.edit,
          onPressed: state.isMutationPending ? null : () => onEdit(type),
          icon: const Icon(AppIcons.edit),
        ),
        IconButton(
          tooltip: type.isActive ? l10n.deactivate : l10n.reactivate,
          onPressed: state.isMutationPending
              ? null
              : () => type.isActive ? onDeactivate(type) : onReactivate(type),
          icon: Icon(type.isActive ? AppIcons.deactivate : AppIcons.reactivate),
        ),
      ],
    );
  }
}
