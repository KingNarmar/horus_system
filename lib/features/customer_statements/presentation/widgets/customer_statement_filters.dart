import 'package:flutter/material.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../customers/domain/entities/customer.dart';
import '../constants/customer_statements_presentation_constants.dart';
import '../helpers/customer_statement_formatters.dart';
import '../localization/customer_statements_localizations.dart';

final class CustomerStatementFilters extends StatelessWidget {
  final List<Customer> customers;
  final String? selectedCustomerId;
  final DateTime? fromDate;
  final DateTime? toDate;
  final bool canApply;
  final ValueChanged<String?> onCustomerChanged;
  final ValueChanged<DateTime?> onFromDateChanged;
  final ValueChanged<DateTime?> onToDateChanged;
  final VoidCallback onApply;
  final VoidCallback onClearDates;

  const CustomerStatementFilters({
    required this.customers,
    required this.selectedCustomerId,
    required this.fromDate,
    required this.toDate,
    required this.canApply,
    required this.onCustomerChanged,
    required this.onFromDateChanged,
    required this.onToDateChanged,
    required this.onApply,
    required this.onClearDates,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final strings = context.customerStatementsL10n;
    final customerField = InputDecorator(
      decoration: InputDecoration(labelText: strings.selectCustomer),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedCustomerId,
          isExpanded: true,
          hint: Text(strings.selectCustomer),
          items: customers
              .map(
                (customer) => DropdownMenuItem<String>(
                  value: customer.id,
                  child: Text(
                    strings.customerOption(
                      name: customer.name,
                      isActive: customer.isActive,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(growable: false),
          onChanged: onCustomerChanged,
        ),
      ),
    );

    final fromField = _DateFilterField(
      label: strings.fromDate,
      value: fromDate,
      onChanged: onFromDateChanged,
    );
    final toField = _DateFilterField(
      label: strings.toDate,
      value: toDate,
      onChanged: onToDateChanged,
    );
    final actions = Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        FilledButton.icon(
          key: const ValueKey('customerStatementApplyButton'),
          onPressed: canApply ? onApply : null,
          icon: const Icon(AppIcons.view),
          label: Text(strings.applyFilters),
        ),
        OutlinedButton.icon(
          onPressed: fromDate == null && toDate == null ? null : onClearDates,
          icon: const Icon(AppIcons.clear),
          label: Text(strings.clearDates),
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < AppSizes.dataTableBreakpoint) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              customerField,
              const SizedBox(height: AppSpacing.md),
              fromField,
              const SizedBox(height: AppSpacing.md),
              toField,
              const SizedBox(height: AppSpacing.md),
              actions,
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(flex: 2, child: customerField),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: fromField),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: toField),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Align(alignment: AlignmentDirectional.centerEnd, child: actions),
          ],
        );
      },
    );
  }
}

final class _DateFilterField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;

  const _DateFilterField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final strings = context.customerStatementsL10n;
    final localeName = Localizations.localeOf(context).toLanguageTag();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickDate(context),
                icon: const Icon(AppIcons.calendar),
                label: Text(
                  value == null
                      ? strings.chooseDate
                      : formatCustomerStatementDate(value!, localeName),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            if (value != null) ...[
              const SizedBox(width: AppSpacing.xs),
              IconButton(
                tooltip: strings.clearDate,
                onPressed: () => onChanged(null),
                icon: const Icon(AppIcons.clear),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final earliest = CustomerStatementsPresentationConstants.earliestDate;
    final latest = CustomerStatementsPresentationConstants.latestDate;
    final today = DateTime.now();
    final candidate = value ?? today;
    final initialDate = candidate.isBefore(earliest)
        ? earliest
        : candidate.isAfter(latest)
        ? latest
        : candidate;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: earliest,
      lastDate: latest,
    );
    if (picked != null && context.mounted) {
      onChanged(DateTime(picked.year, picked.month, picked.day));
    }
  }
}
