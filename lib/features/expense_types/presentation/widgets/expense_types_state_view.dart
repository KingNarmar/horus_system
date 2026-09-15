import 'package:flutter/material.dart';

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

  const ExpenseTypesStateView({
    required this.state,
    required this.onRetry,
    required this.onStatusFilterChanged,
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

  const _Loaded({required this.state, required this.onStatusFilterChanged});

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
                return _TypesTable(types: types);
              }
              return _TypesCards(types: types);
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

  const _TypesTable({required this.types});

  @override
  Widget build(BuildContext context) {
    final l10n = context.expenseTypesL10n;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          DataColumn(label: Text(l10n.nameLabel)),
          DataColumn(label: Text(l10n.status)),
        ],
        rows: types
            .map(
              (type) => DataRow(
                cells: [
                  DataCell(Text(type.name)),
                  DataCell(
                    Chip(
                      label: Text(type.isActive ? l10n.active : l10n.inactive),
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

  const _TypesCards({required this.types});

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
              ),
            ),
          )
          .toList(),
    );
  }
}
