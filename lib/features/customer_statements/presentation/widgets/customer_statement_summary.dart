import 'package:flutter/material.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/domain/value_objects/money.dart';
import '../../../../core/localization/money_formatter.dart';
import '../../domain/entities/customer_statement.dart';
import '../localization/customer_statements_localizations.dart';

final class CustomerStatementSummary extends StatelessWidget {
  final CustomerStatement statement;

  const CustomerStatementSummary({required this.statement, super.key});

  @override
  Widget build(BuildContext context) {
    final strings = context.customerStatementsL10n;
    final items = [
      _SummaryItem(strings.openingBalance, statement.openingBalance),
      _SummaryItem(strings.invoiced, statement.totalInvoiced),
      _SummaryItem(strings.paid, statement.totalPaid),
      _SummaryItem(strings.outstanding, statement.closingBalance),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= AppSizes.dataTableBreakpoint
            ? 4
            : constraints.maxWidth >= AppSizes.detailsStackBreakpoint
            ? 2
            : 1;
        final spacing = AppSpacing.md * (columns - 1);
        final width = (constraints.maxWidth - spacing) / columns;

        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: items
              .map(
                (item) => SizedBox(
                  width: width,
                  child: _SummaryCard(
                    item: item,
                    fractionDigits: statement.fractionDigits,
                  ),
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }
}

final class _SummaryItem {
  final String label;
  final Money money;

  const _SummaryItem(this.label, this.money);
}

final class _SummaryCard extends StatelessWidget {
  final _SummaryItem item;
  final int fractionDigits;

  const _SummaryCard({required this.item, required this.fractionDigits});

  @override
  Widget build(BuildContext context) {
    final localeName = Localizations.localeOf(context).toLanguageTag();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.label, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: AppSpacing.sm),
            Text(
              formatLocalizedMoney(
                item.money,
                fractionDigits: fractionDigits,
                localeName: localeName,
              ),
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
